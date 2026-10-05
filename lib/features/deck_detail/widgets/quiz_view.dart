import 'package:flutter/material.dart';

import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../data/models/quiz_question.dart';
import '../../../data/models/study_deck.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/progress_ring.dart';

/// A multiple-choice quiz: answer each question, see the explanation, then
/// get a score with the questions you missed.
class QuizView extends StatefulWidget {
  final StudyDeck deck;
  const QuizView({super.key, required this.deck});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _showAnswer = false;
  bool _finished = false;

  /// The option chosen for each question, by question index.
  final Map<int, int> _answers = {};

  // Keeps the quiz where it was when switching between the two tabs.
  @override
  bool get wantKeepAlive => true;

  List<QuizQuestion> get _quiz => widget.deck.quizQuestions;

  int get _score {
    var score = 0;
    _answers.forEach((questionIndex, chosen) {
      if (questionIndex < _quiz.length &&
          chosen == _quiz[questionIndex].correctIndex) {
        score++;
      }
    });
    return score;
  }

  void _check() {
    final selected = _selectedIndex;
    if (selected == null) return;
    setState(() {
      _answers[_currentIndex] = selected;
      _showAnswer = true;
    });
  }

  void _next() {
    setState(() {
      if (_currentIndex < _quiz.length - 1) {
        _currentIndex++;
        _selectedIndex = null;
        _showAnswer = false;
      } else {
        _finished = true;
      }
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _selectedIndex = null;
      _showAnswer = false;
      _finished = false;
      _answers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_quiz.isEmpty) {
      return const EmptyState(
        icon: Icons.quiz_outlined,
        title: 'No quiz questions',
        subtitle: 'This deck was made without a quiz.',
      );
    }

    // The deck can change underneath (for example after a reset).
    if (_currentIndex >= _quiz.length) {
      _currentIndex = 0;
    }

    return _finished ? _buildResults(context) : _buildQuestion(context);
  }

  Widget _buildQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final q = _quiz[_currentIndex];

    return Column(
      children: [
        Expanded(
          // Scrolls, so long questions or explanations never overflow.
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _quiz.length,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Question ${_currentIndex + 1} of ${_quiz.length}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(q.question, style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              for (int i = 0; i < q.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionTile(
                    text: q.options[i],
                    letter: String.fromCharCode(65 + i),
                    state: _optionState(q, i),
                    onTap: _showAnswer
                        ? null
                        : () => setState(() => _selectedIndex = i),
                  ),
                ),
              if (_showAnswer && q.explanation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.tint,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q.explanation,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // The action stays pinned under the scrolling question.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: _showAnswer
              ? AppButton(
                  label: _currentIndex < _quiz.length - 1
                      ? 'Next question'
                      : 'See results',
                  onPressed: _next,
                )
              : AppButton(
                  label: 'Check answer',
                  onPressed: _selectedIndex == null ? null : _check,
                ),
        ),
      ],
    );
  }

  _OptionState _optionState(QuizQuestion q, int index) {
    final isCorrect = index == q.correctIndex;
    final isSelected = index == _selectedIndex;
    if (_showAnswer) {
      if (isCorrect) return _OptionState.correct;
      if (isSelected) return _OptionState.wrong;
      return _OptionState.idle;
    }
    return isSelected ? _OptionState.selected : _OptionState.idle;
  }

  Widget _buildResults(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final total = _quiz.length;
    final score = _score;
    final ratio = total == 0 ? 0.0 : score / total;

    final String headline;
    if (score == total) {
      headline = 'Perfect score';
    } else if (ratio >= 0.7) {
      headline = 'Nicely done';
    } else if (ratio >= 0.4) {
      headline = 'Getting there';
    } else {
      headline = 'Worth another look';
    }

    // The questions answered wrongly, to learn from.
    final missed = <int>[
      for (int i = 0; i < total; i++)
        if (_answers[i] != _quiz[i].correctIndex) i,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: ProgressRing(
            value: ratio,
            size: 112,
            strokeWidth: 9,
            color: ratio >= 0.7 ? palette.good : palette.hard,
            trackColor: palette.tint,
            center: Text('$score/$total', style: theme.textTheme.headlineSmall),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          score == 1
              ? 'You got 1 question right out of $total.'
              : 'You got $score questions right out of $total.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Take the quiz again',
          icon: Icons.refresh,
          onPressed: _restart,
        ),
        if (missed.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Questions to revisit', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final i in missed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MissedQuestion(
                question: _quiz[i],
                chosenIndex: _answers[i],
              ),
            ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String text;

  /// A, B, C, D.
  final String letter;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.text,
    required this.letter,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final Color accent;
    switch (state) {
      case _OptionState.selected:
        accent = theme.colorScheme.primary;
        break;
      case _OptionState.correct:
        accent = palette.good;
        break;
      case _OptionState.wrong:
        accent = palette.again;
        break;
      case _OptionState.idle:
        accent = palette.line;
        break;
    }
    final isIdle = state == _OptionState.idle;

    return Material(
      color:
          isIdle ? theme.colorScheme.surface : accent.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(color: accent, width: isIdle ? 1 : 1.8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isIdle ? palette.tint : accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isIdle ? palette.muted : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text, style: theme.textTheme.bodyLarge),
              ),
              if (state == _OptionState.correct)
                Icon(Icons.check_circle, color: palette.good),
              if (state == _OptionState.wrong)
                Icon(Icons.cancel, color: palette.again),
            ],
          ),
        ),
      ),
    );
  }
}

/// One wrongly answered question on the results screen, with the right
/// answer and the explanation.
class _MissedQuestion extends StatelessWidget {
  final QuizQuestion question;
  final int? chosenIndex;

  const _MissedQuestion({required this.question, required this.chosenIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final chosen = chosenIndex;
    final String? chosenText =
        (chosen != null && chosen >= 0 && chosen < question.options.length)
            ? question.options[chosen]
            : null;
    final hasCorrect = question.correctIndex >= 0 &&
        question.correctIndex < question.options.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (chosenText != null)
            _AnswerLine(
              icon: Icons.close,
              color: palette.again,
              text: chosenText,
            ),
          if (hasCorrect)
            _AnswerLine(
              icon: Icons.check,
              color: palette.good,
              text: question.options[question.correctIndex],
            ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              question.explanation,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _AnswerLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
