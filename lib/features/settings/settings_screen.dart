import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constant/app_colors.dart';
import '../../core/constant/app_sizes.dart';
import '../../data/services/providers.dart';
import '../shared/widgets/dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _minGoal = 5;
  static const _maxGoal = 100;
  static const _goalStep = 5;

  Future<void> _deleteEverything(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete all decks?',
      message: 'Every deck, its cards and your study history will be '
          'removed from this device. This cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(decksProvider.notifier).deleteAllDecks();
    await ref.read(studyStatsProvider.notifier).clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All decks deleted')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final deckCount = ref.watch(decksProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Appearance ──────────────────────────────────────
          const _SectionTitle('Appearance'),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Theme', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Choose light or dark, or follow your phone\'s setting.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      notifier.setThemeMode(selection.first),
                ),
              ],
            ),
          ),

          // ── Daily goal ──────────────────────────────────────
          const _SectionTitle('Study'),
          _SettingsCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily goal', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Cards to review each day',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Lower the goal',
                  onPressed: settings.dailyGoal <= _minGoal
                      ? null
                      : () =>
                          notifier.setDailyGoal(settings.dailyGoal - _goalStep),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${settings.dailyGoal}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Raise the goal',
                  onPressed: settings.dailyGoal >= _maxGoal
                      ? null
                      : () =>
                          notifier.setDailyGoal(settings.dailyGoal + _goalStep),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),

          // ── About ───────────────────────────────────────────
          const _SectionTitle('About'),
          _SettingsCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _InfoRow(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Powered by',
                  value: 'Google Gemini',
                ),
                Divider(indent: 52, color: palette.line),
                const _InfoRow(
                  icon: Icons.storage_outlined,
                  title: 'Storage',
                  value: 'On this device only',
                ),
                Divider(indent: 52, color: palette.line),
                const _InfoRow(
                  icon: Icons.info_outline,
                  title: 'Version',
                  value: '1.0.0',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.privacy_tip_outlined, size: 18, color: palette.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your notes are sent to Gemini only when you create a '
                  'deck. Decks and progress stay on your device.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),

          // ── Data ────────────────────────────────────────────
          const _SectionTitle('Data'),
          OutlinedButton.icon(
            onPressed:
                deckCount == 0 ? null : () => _deleteEverything(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            icon: const Icon(Icons.delete_outline),
            label: Text(
              deckCount == 0 ? 'No decks to delete' : 'Delete all decks',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SettingsCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.md),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: context.palette.line),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.muted),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
