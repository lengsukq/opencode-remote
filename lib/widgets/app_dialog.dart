import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared dialog helpers for consistent dialog styling.
///
/// Usage:
/// ```dart
/// final name = await AppDialog.showTextInput(context, title: '输入名称');
/// final confirmed = await AppDialog.showConfirm(context, title: '确认', message: '确定删除？');
/// ```
class AppDialog {
  AppDialog._();

  /// Shows a dialog with a single text input field.
  ///
  /// Returns the entered text, or null if cancelled.
  static Future<String?> showTextInput(
    BuildContext context, {
    required String title,
    String hintText = '',
    String? initialValue,
    String confirmLabel = '确定',
    String cancelLabel = '取消',
    bool obscureText = false,
    TextInputType? keyboardType,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          autofocus: true,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.borderFocused),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  /// Shows a confirmation dialog with custom message.
  ///
  /// Returns true if confirmed, false if cancelled.
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '确定',
    String cancelLabel = '取消',
    Color? confirmColor,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog with custom content and optional actions.
  ///
  /// Use for complex dialogs that don't fit the text input or confirm patterns.
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    String cancelLabel = '取消',
    bool showDefaultCancel = true,
  }) async {
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: content,
        actions: [
          if (showDefaultCancel)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }
}
