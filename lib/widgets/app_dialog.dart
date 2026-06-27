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
    return showDialog<String>(
      context: context,
      builder: (ctx) => _TextInputDialogContent(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        obscureText: obscureText,
        keyboardType: keyboardType,
      ),
    );
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

/// Stateful dialog content that manages [TextEditingController] lifecycle,
/// ensuring the controller isn't used after the dialog's dismiss animation ends.
class _TextInputDialogContent extends StatefulWidget {
  final String title;
  final String hintText;
  final String? initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _TextInputDialogContent({
    required this.title,
    required this.hintText,
    this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.obscureText,
    this.keyboardType,
  });

  @override
  State<_TextInputDialogContent> createState() => _TextInputDialogContentState();
}

class _TextInputDialogContentState extends State<_TextInputDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.title, style: const TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        autofocus: true,
        controller: _controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
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
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
