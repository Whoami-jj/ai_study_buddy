import 'package:flutter/material.dart';

import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';

/// Shown over the Create screen while a deck is being made.
///
/// Lists the steps so the wait feels explained: reading the material (for
/// a PDF or photo), then writing the cards and quiz.
class GeneratingLoader extends StatelessWidget {
  /// The steps, in order.
  final List<String> steps;

  /// Index of the step in progress. Earlier steps show as done.
  final int currentStep;

  const GeneratingLoader({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Making your deck', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'This usually takes 10 to 20 seconds.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              for (int i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: i < currentStep
                            ? Icon(Icons.check_circle,
                                size: 22, color: palette.good)
                            : i == currentStep
                                ? const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  )
                                : Icon(Icons.circle_outlined,
                                    size: 22, color: palette.line),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          steps[i],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: i <= currentStep ? null : palette.muted,
                            fontWeight:
                                i == currentStep ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
