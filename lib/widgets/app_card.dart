import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/glass_effect.dart';

/// A reusable card container with consistent theming.
///
/// Wraps content in a [GlassCard] with the project's standard
/// glassmorphism effect, large rounded corners, and 3D shadows.
/// Supports variants via optional parameters.
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
///   boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
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
    return GlassCard(
      padding: padding ?? AppColors.kPaddingCard,
      borderRadius: borderRadius,
      foregroundColor: color,
      boxShadow: boxShadow,
      onTap: onTap,
      child: child,
    );
  }
}
