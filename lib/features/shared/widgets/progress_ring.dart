import 'package:flutter/material.dart';

/// A circular progress ring with something in the middle (a number, an
/// icon).
class ProgressRing extends StatelessWidget {
  /// 0.0 to 1.0.
  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? center;

  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.trackColor,
    this.size = 56,
    this.strokeWidth = 5,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0).toDouble(),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: trackColor,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}
