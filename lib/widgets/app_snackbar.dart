import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared SnackBar helpers for consistent notification styling.
///
/// Usage:
/// ```dart
/// AppSnackBar.show(context, '操作成功');
/// AppSnackBar.error(context, '操作失败: $e');
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// Shows a standard info SnackBar with themed styling.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an error SnackBar with danger-colored background.
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.danger,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a success SnackBar with success-colored background.
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
