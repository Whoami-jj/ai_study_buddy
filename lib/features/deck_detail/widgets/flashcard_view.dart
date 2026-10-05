import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/study_deck.dart';
import '../../../data/services/providers.dart';
import '../../shared/widgets/dialogs.dart';
import '../../shared/widgets/empty_state.dart';
import 'card_editor_sheet.dart';

/// The deck's flashcards as a list. Tap a card to see its answer; use its
/// menu to edit or delete it. New cards can be added by hand.
class FlashcardView extends ConsumerWidget {
  final StudyDeck deck;
  const FlashcardView({super.key, required this.deck});

  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    final result = await showCardEditorSheet(context);
    if (result == null) return;
    await ref
        .read(decksProvider.notifier)
        .addCard(deck, result.question, result.answer);
  }

  Future<void> _editCard(
      BuildContext context, WidgetRef ref, Flashcard card) async {
    final result = await showCardEditorSheet(context, card: card);
    if (result == null) return;
    await ref
        .read(decksProvider.notifier)
        .updateCard(deck, card, result.question, result.answer);
  }

  Future<void> _deleteCard(
      BuildContext context, WidgetRef ref, Flashcard card) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this card?',
      message: 'The card and its progress will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(decksProvider.notifier).deleteCard(deck, card);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (deck.flashcards.isEmpty) {
      return EmptyState(
        icon: Icons.style_outlined,
        title: 'No flashcards',
        subtitle: 'Add your own cards to this deck.',
        action: FilledButton.icon(
          onPressed: () => _addCard(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add a card'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      // One extra row at the top for "Add a card".
      itemCount: deck.flashcards.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addCard(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add a card'),
            ),
          );
        }
        final card = deck.flashcards[i - 1];
        return _FlashcardTile(
          // Keeps each tile's open/closed state with its card.
          key: ValueKey(card.id),
          card: card,
          onEdit: () => _editCard(context, ref, card),
          onDelete: () => _deleteCard(context, ref, card),
        );
      },
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlashcardTile({
    super.key,
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    // A card that has never been reviewed. (A card that was reviewed and
    // forgotten also has zero repetitions, but it has an interval.)
    final isUnseen = card.repetitions == 0 && card.intervalDays == 0;

    // Where the card is in its learning life.
    final String status;
    final Color statusColor;
    if (isUnseen) {
      status = 'New';
      statusColor = palette.easy;
    } else if (card.isMastered) {
      status = 'Mastered';
      statusColor = palette.good;
    } else {
      status = 'Learning';
      statusColor = palette.hard;
    }

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: palette.line),
      ),
      child: Theme(
        // Removes the lines ExpansionTile draws when open.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 16, right: 4),
          childrenPadding: EdgeInsets.zero,
          title: Text(card.question, style: theme.textTheme.titleSmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Pill(text: status, color: statusColor),
                if (!isUnseen)
                  _Pill(
                    text: AppDateUtils.dueLabel(card.dueDate),
                    color: card.isDue ? palette.again : palette.muted,
                  ),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Card options',
            icon: Icon(Icons.more_vert, color: palette.muted),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: palette.tint,
              child: Text(
                card.answer,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
