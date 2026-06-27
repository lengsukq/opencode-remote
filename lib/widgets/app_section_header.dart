import 'package:flutter/material.dart';
import '../theme.dart';

/// A section header with standardized iOS-style styling.
///
/// Renders the title in all-caps with a secondary text color, matching the
/// iOS Settings-style section header appearance.
///
/// Usage:
/// ```dart
/// AppSectionHeader('配置')
///
/// AppSectionHeader('服务器', padding: EdgeInsets.only(bottom: 12))
/// ```
class AppSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;

  const AppSectionHeader(
    this.title, {
    super.key,
    this.padding = AppColors.kPaddingSection,
    this.fontSize = 0,
    this.color,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final size = fontSize > 0 ? fontSize : 13.0;
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color ?? AppColors.textSecondary,
          fontSize: size,
          fontWeight: fontWeight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
