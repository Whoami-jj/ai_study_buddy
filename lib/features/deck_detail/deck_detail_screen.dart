import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constant/app_colors.dart';
import '../../core/constant/app_sizes.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/study_deck.dart';
import '../../data/services/providers.dart';
import '../shared/widgets/dialogs.dart';
import 'widgets/flashcard_view.dart';
import 'widgets/quiz_view.dart';

class DeckDetailScreen extends ConsumerStatefulWidget {
  final String deckId;
  const DeckDetailScreen({super.key, required this.deckId});

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _rename(StudyDeck deck) async {
    final title = await showTextInputDialog(
      context,
      title: 'Rename deck',
      confirmLabel: 'Rename',
      initialValue: deck.title,
    );
    if (title == null) return;
    await ref.read(decksProvider.notifier).renameDeck(deck, title);
  }

  Future<void> _resetProgress(StudyDeck deck) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset progress?',
      message: 'Every card in this deck goes back to new, and its review '
          'history is cleared. The cards themselves are kept.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(decksProvider.notifier).resetProgress(deck);
  }

  Future<void> _delete(StudyDeck deck) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${deck.title}"?',
      message: 'Its cards, quiz and progress will be removed. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(decksProvider.notifier).deleteDeck(widget.deckId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watching the list (not just the notifier) rebuilds this screen when
    // a card is reviewed, added, edited or deleted.
    final decks = ref.watch(decksProvider);
    StudyDeck? deck;
    for (final d in decks) {
      if (d.id == widget.deckId) {
        deck = d;
        break;
      }
    }

    if (deck == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This deck no longer exists.')),
      );
    }
    final currentDeck = deck;

    final theme = Theme.of(context);
    final palette = context.palette;
    final due = currentDeck.dueCards;
    final hasCards = currentDeck.flashcards.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentDeck.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Deck options',
            onSelected: (value) {
              if (value == 'rename') _rename(currentDeck);
              if (value == 'reset') _resetProgress(currentDeck);
              if (value == 'delete') _delete(currentDeck);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'reset', child: Text('Reset progress')),
              PopupMenuItem(value: 'delete', child: Text('Delete deck')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Numbers and the two ways to study ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DeckStats(deck: currentDeck),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: due == 0
                            ? null
                            : () => context.push('/review/${widget.deckId}'),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label:
                            Text(due == 0 ? 'Nothing due' : 'Review $due due'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: hasCards
                            ? () => context.push('/practice/${widget.deckId}')
                            : null,
                        icon: const Icon(Icons.repeat_rounded),
                        label: const Text('Practice all'),
                      ),
                    ),
                  ],
                ),
                if (currentDeck.totalReviews > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last studied '
                    '${AppDateUtils.relativeDay(currentDeck.lastReviewedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          // ── Tabs ────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: palette.muted,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: palette.line,
            labelStyle: theme.textTheme.labelLarge,
            tabs: [
              Tab(text: 'Cards (${currentDeck.flashcards.length})'),
              Tab(text: 'Quiz (${currentDeck.quizQuestions.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FlashcardView(deck: currentDeck),
                QuizView(deck: currentDeck),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four numbers that sum the deck up: cards, due, mastered, accuracy.
class _DeckStats extends StatelessWidget {
  final StudyDeck deck;
  const _DeckStats({required this.deck});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accuracy =
        deck.totalReviews == 0 ? '–' : '${(deck.accuracy * 100).round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: palette.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Stat(value: '${deck.flashcards.length}', label: 'Cards'),
            ),
            VerticalDivider(width: 1, color: palette.line),
            Expanded(
              child: _Stat(
                value: '${deck.dueCards}',
                label: 'Due',
                // Due cards are the thing to act on, so they get the marker.
                highlighted: deck.dueCards > 0,
              ),
            ),
            VerticalDivider(width: 1, color: palette.line),
            Expanded(
              child: _Stat(value: '${deck.masteredCards}', label: 'Mastered'),
            ),
            VerticalDivider(width: 1, color: palette.line),
            Expanded(child: _Stat(value: accuracy, label: 'Accuracy')),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool highlighted;

  const _Stat({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: highlighted
              ? BoxDecoration(
                  color: palette.highlight,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: highlighted ? palette.onHighlight : null,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
