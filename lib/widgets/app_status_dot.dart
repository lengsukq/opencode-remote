import 'package:flutter/material.dart';

/// A small colored status indicator dot.
///
/// Usage:
/// ```dart
/// AppStatusDot(AppColors.success)  // green = online
/// AppStatusDot(AppColors.danger)   // red = error
/// AppStatusDot(AppColors.warning)  // orange = warning
/// ```
class AppStatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool withGlow;

  const AppStatusDot(
    this.color, {
    super.key,
    this.size = 8,
    this.withGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: withGlow
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: size)]
            : null,
      ),
    );
  }
}
