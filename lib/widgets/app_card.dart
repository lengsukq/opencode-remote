import 'package:flutter/material.dart';
import '../theme.dart';

/// A reusable card container with consistent theming.
///
/// Wraps content in a styled Container with the project's standard
/// surface color, border, and border radius. Supports variants via
/// optional parameters.
///
/// Usage:
/// ```dart
/// AppCard(
///   child: Text('Content'),
/// )
///
/// AppCard(
///   padding: EdgeInsets.all(12),
///   borderRadius: 16,
///   boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
///   child: Text('Shadow card'),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.color,
    this.borderColor,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? AppColors.kPaddingCard,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
