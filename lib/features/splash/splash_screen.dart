import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constant/app_colors.dart';
import '../../core/constant/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.board,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A flashcard with a highlighter mark: the app in one picture.
            Container(
              width: 96,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette.highlight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 64,
                    height: 4,
                    color: AppColors.ink.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 52,
                    height: 4,
                    color: AppColors.ink.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              AppStrings.appName,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: palette.onBoard),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.tagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.onBoard.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
