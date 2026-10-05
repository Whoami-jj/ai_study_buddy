import 'package:flutter/material.dart';

import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';

/// A flat, outlined surface. Tappable when [onTap] is given.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSizes.md),
      child: child,
    );

    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: context.palette.line),
      ),
      child: onTap == null && onLongPress == null
          ? content
          : InkWell(onTap: onTap, onLongPress: onLongPress, child: content),
    );
  }
}
