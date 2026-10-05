import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constant/app_colors.dart';
import '../../core/constant/app_sizes.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/study_deck.dart';
import '../../data/services/providers.dart';
import '../shared/widgets/app_button.dart';

/// One card in the session, with the deck it belongs to.
class _ReviewItem {
  final StudyDeck deck;
  final Flashcard card;
  const _ReviewItem(this.deck, this.card);
}

/// Goes through flashcards one at a time.
///
/// * With a [deckId]: the cards that are due in that deck.
/// * Without one: every due card, across all decks.
/// * With [practice]: every card in the deck, due or not, and nothing is
///   saved, so the schedule is left alone.
class ReviewScreen extends ConsumerStatefulWidget {
  final String? deckId;
  final bool practice;

  const ReviewScreen({super.key, this.deckId, this.practice = false});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final List<_ReviewItem> _queue = [];
  int _index = 0;
  bool _flipped = false;
  bool _finished = false;
  bool _saving = false;

  /// Cards in the session when it started (repeats not counted).
  int _cardCount = 0;

  int _again = 0;
  int _hard = 0;
  int _good = 0;
  int _easy = 0;

  @override
  void initState() {
    super.initState();
    final decks = ref.read(decksProvider);
    final deckId = widget.deckId;

    for (final deck in decks) {
      if (deckId != null && deck.id != deckId) continue;
      for (final card in deck.flashcards) {
        if (widget.practice || card.isDue) {
          _queue.add(_ReviewItem(deck, card));
        }
      }
    }
    _cardCount = _queue.length;
  }

  Future<void> _rate(int quality) async {
    if (_saving || _queue.isEmpty) return;
    _saving = true;

    final item = _queue[_index];

    // Practice leaves the schedule and the daily count untouched.
    if (!widget.practice) {
      await ref
          .read(decksProvider.notifier)
          .reviewCard(item.deck, item.card, quality);
    }
    if (!mounted) return;

    setState(() {
      if (quality < 3) {
        _again++;
        // A forgotten card comes round again at the end of this session.
        _queue.add(item);
      } else if (quality == 3) {
        _hard++;
      } else if (quality == 4) {
        _good++;
      } else {
        _easy++;
      }

      if (_index < _queue.length - 1) {
        _index++;
        _flipped = false;
      } else {
        _finished = true;
      }
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) return _buildNothingToReview(context);
    if (_finished) return _buildSummary(context);

    final theme = Theme.of(context);
    final palette = context.palette;
    final item = _queue[_index];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.practice ? 'Practice' : 'Review'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                '${_index + 1} of ${_queue.length}',
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _index / _queue.length,
                  minHeight: 6,
                ),
              ),
              // When reviewing across decks, say which deck this card is from.
              if (widget.deckId == null) ...[
                const SizedBox(height: 12),
                Text(
                  item.deck.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: KeyedSubtree(
                  // A new key per card, so the next card starts face up
                  // without playing the flip backwards.
                  key: ValueKey(_index),
                  child: _FlipCard(
                    flipped: _flipped,
                    onTap: () => setState(() => _flipped = !_flipped),
                    front: _CardFace(
                      label: 'Question',
                      text: item.card.question,
                      hint: 'Tap the card to see the answer',
                      emphasised: true,
                    ),
                    back: _CardFace(
                      label: 'Answer',
                      text: item.card.answer,
                      hint: 'Tap to see the question again',
                      emphasised: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_flipped)
                AppButton(
                  label: 'Show answer',
                  onPressed: () => setState(() => _flipped = true),
                )
              else if (widget.practice)
                Row(
                  children: [
                    _RatingButton(
                      label: 'Didn\'t know',
                      caption: 'See it again',
                      color: palette.again,
                      onTap: () => _rate(0),
                    ),
                    const SizedBox(width: 8),
                    _RatingButton(
                      label: 'Knew it',
                      caption: 'Next card',
                      color: palette.good,
                      onTap: () => _rate(4),
                    ),
                  ],
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'How well did you know this?',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _RatingButton(
                          label: 'Again',
                          caption: 'Forgot',
                          color: palette.again,
                          onTap: () => _rate(0),
                        ),
                        const SizedBox(width: 8),
                        _RatingButton(
                          label: 'Hard',
                          caption: 'Struggled',
                          color: palette.hard,
                          onTap: () => _rate(3),
                        ),
                        const SizedBox(width: 8),
                        _RatingButton(
                          label: 'Good',
                          caption: 'Knew it',
                          color: palette.good,
                          onTap: () => _rate(4),
                        ),
                        const SizedBox(width: 8),
                        _RatingButton(
                          label: 'Easy',
                          caption: 'Instantly',
                          color: palette.easy,
                          onTap: () => _rate(5),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when there is nothing to go through.
  Widget _buildNothingToReview(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final deckId = widget.deckId;

    // In a single deck, offer to practise its cards anyway.
    var canPractice = false;
    if (deckId != null && !widget.practice) {
      final deck = ref.read(decksProvider.notifier).deckById(deckId);
      canPractice = deck != null && deck.flashcards.isNotEmpty;
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 64, color: palette.good),
              const SizedBox(height: 16),
              Text(
                widget.practice ? 'No cards to practise' : 'All caught up',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.practice
                    ? 'This deck has no cards yet.'
                    : 'No cards are due right now. They come back when it '
                        'is time to see them again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: palette.muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              if (canPractice) ...[
                AppButton(
                  label: 'Practice all cards anyway',
                  icon: Icons.repeat_rounded,
                  outlined: true,
                  onPressed: () => context.pushReplacement('/practice/$deckId'),
                ),
                const SizedBox(height: 10),
              ],
              AppButton(label: 'Back', onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown after the last card.
  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final streak = ref.watch(studyStatsProvider).streak;

    final cardsText = _cardCount == 1 ? '1 card' : '$_cardCount cards';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.celebration_rounded,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                widget.practice ? 'Practice complete' : 'Session complete',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                widget.practice
                    ? 'You went through $cardsText. '
                        'Your schedule is unchanged.'
                    : 'You reviewed $cardsText.',
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: palette.line),
                ),
                child: Row(
                  children: widget.practice
                      ? [
                          _SummaryCount(
                              count: _again,
                              label: 'Didn\'t know',
                              color: palette.again),
                          _SummaryCount(
                              count: _good,
                              label: 'Knew it',
                              color: palette.good),
                        ]
                      : [
                          _SummaryCount(
                              count: _again,
                              label: 'Again',
                              color: palette.again),
                          _SummaryCount(
                              count: _hard, label: 'Hard', color: palette.hard),
                          _SummaryCount(
                              count: _good, label: 'Good', color: palette.good),
                          _SummaryCount(
                              count: _easy, label: 'Easy', color: palette.easy),
                        ],
                ),
              ),
              if (!widget.practice && streak > 0) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 18, color: palette.hard),
                    const SizedBox(width: 6),
                    Text(
                      streak == 1 ? '1-day streak' : '$streak-day streak',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ],
              const Spacer(),
              AppButton(label: 'Done', onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that turns over when tapped, like a real flashcard.
class _FlipCard extends StatelessWidget {
  final bool flipped;
  final Widget front;
  final Widget back;
  final VoidCallback onTap;

  const _FlipCard({
    required this.flipped,
    required this.front,
    required this.back,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Respect the system "reduce motion" setting.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: flipped ? 1.0 : 0.0),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          final showBack = value > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // a little perspective
              ..rotateY(value * math.pi),
            child: showBack
                // The back is mirrored again so its text reads normally.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: back,
                  )
                : front,
          );
        },
      ),
    );
  }
}

/// One side of a flashcard, drawn like an index card: a label, a ruled
/// line, then the text.
class _CardFace extends StatelessWidget {
  final String label;
  final String text;
  final String hint;

  /// The question side uses larger type than the answer side.
  final bool emphasised;

  const _CardFace({
    required this.label,
    required this.text,
    required this.hint,
    required this.emphasised,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 10),
          // The red rule across the top of an index card.
          Container(height: 1.5, color: palette.again.withValues(alpha: 0.55)),
          Expanded(
            child: Center(
              // Long text scrolls inside the card.
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: (emphasised
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.titleLarge)
                      ?.copyWith(height: 1.3),
                ),
              ),
            ),
          ),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.caption,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    caption,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCount extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryCount({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
