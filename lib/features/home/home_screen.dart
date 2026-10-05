import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constant/app_colors.dart';
import '../../core/constant/app_sizes.dart';
import '../../core/constant/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/study_deck.dart';
import '../../data/services/providers.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/dialogs.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/progress_ring.dart';

enum _DeckSort { recent, dueFirst, alphabetical }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _DeckSort _sort = _DeckSort.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The decks to show: filtered by the search text, then sorted.
  List<StudyDeck> _visibleDecks(List<StudyDeck> decks) {
    final query = _query.trim().toLowerCase();
    final result = query.isEmpty
        ? [...decks]
        : decks.where((d) => d.title.toLowerCase().contains(query)).toList();

    switch (_sort) {
      case _DeckSort.recent:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _DeckSort.dueFirst:
        result.sort((a, b) => b.dueCards.compareTo(a.dueCards));
        break;
      case _DeckSort.alphabetical:
        result.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return result;
  }

  Future<void> _renameDeck(StudyDeck deck) async {
    final title = await showTextInputDialog(
      context,
      title: 'Rename deck',
      confirmLabel: 'Rename',
      initialValue: deck.title,
    );
    if (title == null) return;
    await ref.read(decksProvider.notifier).renameDeck(deck, title);
  }

  Future<void> _deleteDeck(StudyDeck deck) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${deck.title}"?',
      message: 'Its cards, quiz and progress will be removed. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(decksProvider.notifier).deleteDeck(deck.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final decks = ref.watch(decksProvider);
    final stats = ref.watch(studyStatsProvider);
    final dailyGoal = ref.watch(settingsProvider.select((s) => s.dailyGoal));

    final totalDue = decks.fold<int>(0, (sum, d) => sum + d.dueCards);
    final visible = _visibleDecks(decks);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Greeting ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateUtils.greeting(DateTime.now()),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: palette.muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.appName,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Today ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _TodayCard(
                  stats: stats,
                  dailyGoal: dailyGoal,
                  totalDue: totalDue,
                  hasDecks: decks.isNotEmpty,
                  onReviewAll: () => context.push('/review-all'),
                ),
              ),
            ),

            if (decks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.style_outlined,
                  title: AppStrings.noDecks,
                  subtitle: 'Paste your notes, pick a PDF or take a photo, '
                      'and get flashcards and a quiz in seconds.',
                  action: FilledButton.icon(
                    onPressed: () => context.push('/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create your first deck'),
                  ),
                ),
              )
            else ...[
              // ── Heading, search and sort ────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.myDecks,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      PopupMenuButton<_DeckSort>(
                        tooltip: 'Sort decks',
                        initialValue: _sort,
                        onSelected: (value) => setState(() => _sort = value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _DeckSort.recent,
                            child: Text('Newest first'),
                          ),
                          PopupMenuItem(
                            value: _DeckSort.dueFirst,
                            child: Text('Most due first'),
                          ),
                          PopupMenuItem(
                            value: _DeckSort.alphabetical,
                            child: Text('A to Z'),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort, size: 18, color: palette.muted),
                              const SizedBox(width: 4),
                              Text(
                                'Sort',
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(color: palette.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search is only worth the space once there are a few decks.
              if (decks.length > 3)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search decks',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                ),

              if (visible.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No decks match "$_query".',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: palette.muted),
                    ),
                  ),
                )
              else
                SliverPadding(
                  // Bottom space keeps the last deck clear of the button.
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DeckTile(
                          deck: visible[i],
                          onOpen: () => context.push('/deck/${visible[i].id}'),
                          onRename: () => _renameDeck(visible[i]),
                          onDelete: () => _deleteDeck(visible[i]),
                        ),
                      ),
                      childCount: visible.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: decks.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/create'),
              icon: const Icon(Icons.add),
              label: const Text('New deck'),
            ),
    );
  }
}

/// Today's progress toward the daily goal, the streak, the last seven
/// days, and a shortcut to review everything that is due.
class _TodayCard extends StatelessWidget {
  final StudyStats stats;
  final int dailyGoal;
  final int totalDue;
  final bool hasDecks;
  final VoidCallback onReviewAll;

  const _TodayCard({
    required this.stats,
    required this.dailyGoal,
    required this.totalDue,
    required this.hasDecks,
    required this.onReviewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final onBoard = palette.onBoard;
    final soft = onBoard.withValues(alpha: 0.75);

    final goalReached = stats.reviewedToday >= dailyGoal;
    final progress = dailyGoal == 0 ? 0.0 : stats.reviewedToday / dailyGoal;

    final String streakText;
    if (stats.streak == 0) {
      streakText = 'Review a card to start a streak';
    } else if (stats.streak == 1) {
      streakText = '1-day streak';
    } else {
      streakText = '${stats.streak}-day streak';
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: palette.board,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProgressRing(
                value: progress,
                size: 64,
                strokeWidth: 6,
                color: palette.highlight,
                trackColor: onBoard.withValues(alpha: 0.18),
                center: goalReached
                    ? Icon(Icons.check_rounded, color: palette.highlight)
                    : Text(
                        '${stats.reviewedToday}',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: onBoard),
                      ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goalReached
                          ? 'Daily goal reached'
                          : '${stats.reviewedToday} of $dailyGoal cards today',
                      style:
                          theme.textTheme.titleMedium?.copyWith(color: onBoard),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: stats.streak > 0 ? palette.highlight : soft,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            streakText,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: soft),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _WeekBars(week: stats.week, dailyGoal: dailyGoal),
          if (hasDecks) ...[
            const SizedBox(height: AppSizes.md),
            if (totalDue > 0)
              FilledButton.icon(
                onPressed: onReviewAll,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.highlight,
                  foregroundColor: palette.onHighlight,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  totalDue == 1
                      ? 'Review 1 due card'
                      : 'Review $totalDue due cards',
                ),
              )
            else
              Text(
                'Nothing is due right now. Cards come back when it is '
                'time to see them again.',
                style: theme.textTheme.bodySmall?.copyWith(color: soft),
              ),
          ],
        ],
      ),
    );
  }
}

/// Seven small bars, one per day, ending today.
class _WeekBars extends StatelessWidget {
  final List<DayActivity> week;
  final int dailyGoal;

  const _WeekBars({required this.week, required this.dailyGoal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final onBoard = palette.onBoard;

    const maxBarHeight = 36.0;
    // Bars are scaled against the goal, or the busiest day if that's higher.
    final busiest = week.fold<int>(0, (m, d) => math.max(m, d.reviews));
    final scale = math.max(math.max(busiest, dailyGoal), 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < week.length; i++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  // A day with no reviews still shows a short stub.
                  height: math.max(
                    4.0,
                    maxBarHeight * week[i].reviews / scale,
                  ),
                  decoration: BoxDecoration(
                    color: i == week.length - 1
                        ? palette.highlight
                        : onBoard.withValues(
                            alpha: week[i].reviews > 0 ? 0.6 : 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppDateUtils.weekdayLetter(week[i].day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: onBoard.withValues(
                        alpha: i == week.length - 1 ? 1.0 : 0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DeckTile extends StatelessWidget {
  final StudyDeck deck;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _DeckTile({
    required this.deck,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final total = deck.flashcards.length;
    final mastered = deck.masteredCards;
    final due = deck.dueCards;
    final progress = total == 0 ? 0.0 : mastered / total;
    final tint = AppColors.deckTint(deck.id);
    final initial =
        deck.title.trim().isEmpty ? '?' : deck.title.trim()[0].toUpperCase();

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      child: Row(
        children: [
          // The deck's initial on its own colour, to tell decks apart.
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              initial,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Color.lerp(tint, Colors.white, 0.45)
                    : tint,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deck.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (due > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: palette.highlight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$due due',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.onHighlight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'No cards yet'
                      : '$mastered of $total cards mastered',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Deck options',
            icon: Icon(Icons.more_vert, color: palette.muted),
            onSelected: (value) {
              if (value == 'rename') onRename();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
