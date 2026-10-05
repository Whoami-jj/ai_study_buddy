import 'package:flutter/material.dart';

import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../create_deck_screen.dart';

/// Three tiles for choosing where the study material comes from.
class SourcePicker extends StatelessWidget {
  final SourceMode mode;
  final ValueChanged<SourceMode> onModeChanged;

  const SourcePicker({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SourceTile(
            icon: Icons.notes_rounded,
            label: 'Text',
            active: mode == SourceMode.text,
            onTap: () => onModeChanged(SourceMode.text),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SourceTile(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF',
            active: mode == SourceMode.pdf,
            onTap: () => onModeChanged(SourceMode.pdf),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: 'Photo',
            active: mode == SourceMode.image,
            onTap: () => onModeChanged(SourceMode.image),
          ),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final primary = theme.colorScheme.primary;

    return Material(
      color:
          active ? primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(
          color: active ? primary : palette.line,
          width: active ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: active ? primary : palette.muted, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: active ? primary : palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
