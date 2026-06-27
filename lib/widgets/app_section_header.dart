import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/responsive_values.dart';

/// A section header with standardized styling for form sections.
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
    this.padding = const EdgeInsets.only(bottom: 8),
    this.fontSize = 0, // 0 means use responsive default
    this.color,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textSecondary,
          fontSize: fontSize > 0 ? fontSize : R.smallFontSize(context),
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
