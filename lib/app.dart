import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/providers.dart';

class StudyBuddyApp extends ConsumerWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Light, dark, or follow the phone. Chosen in Settings and remembered.
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp.router(
      title: 'AI Study Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
