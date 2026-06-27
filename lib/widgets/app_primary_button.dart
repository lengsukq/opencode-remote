import 'package:flutter/material.dart';
import '../theme.dart';

/// A reusable primary button with consistent theming.
///
/// Usage:
/// ```dart
/// AppPrimaryButton(
///   label: '确定',
///   onPressed: () {},
/// )
///
/// AppPrimaryButton(
///   label: '保存',
///   icon: Icons.save,
///   onPressed: _save,
///   expanded: true,
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Color? backgroundColor;
  final double? height;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.backgroundColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final minSize = expanded
        ? Size(double.infinity, height ?? 44)
        : Size(0, height ?? 44);

    final button = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        minimumSize: minSize,
      ),
      onPressed: onPressed,
      icon: icon != null ? Icon(icon!, size: 18) : const SizedBox.shrink(),
      label: Text(label),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
