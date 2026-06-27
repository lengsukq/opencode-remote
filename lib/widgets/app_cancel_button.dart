import 'package:flutter/material.dart';
import '../theme.dart';

/// A reusable cancel/text button with consistent theming.
///
/// Usage:
/// ```dart
/// AppCancelButton(
///   label: '取消',
///   onPressed: () => Navigator.pop(context),
/// )
/// ```
class AppCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppCancelButton({super.key, this.label = '取消', this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? () => Navigator.pop(context),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
