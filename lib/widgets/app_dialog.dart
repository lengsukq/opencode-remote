import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/glass_effect.dart';

/// Shared dialog helpers for consistent dialog styling with iOS glassmorphism.
///
/// Uses [GlassDialog] for the glass-blur background, large rounded corners
/// (20px), and 3D depth via shadow level 4.
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
      builder: (ctx) => _buildGlassDialog(
        context: ctx,
        title: title,
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
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
      builder: (ctx) => _buildGlassCustom<T>(
        context: ctx,
        title: title,
        content: content,
        actions: actions,
        cancelLabel: cancelLabel,
        showDefaultCancel: showDefaultCancel,
      ),
    );
  }

  // ==================== Internal Builders ====================

  static Widget _buildGlassDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required String cancelLabel,
    required String confirmLabel,
    Color? confirmColor,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.kMediumBorderRadius),
          boxShadow: AppColors.shadowLevel4,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.kMediumBorderRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Glass.dialogBg(context),
                borderRadius: BorderRadius.circular(
                  AppColors.kMediumBorderRadius,
                ),
                border: Border.all(color: Glass.border(context), width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    content,
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            cancelLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: confirmColor ?? AppColors.primary,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(confirmLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildGlassCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    String cancelLabel = '取消',
    bool showDefaultCancel = true,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.kMediumBorderRadius),
          boxShadow: AppColors.shadowLevel4,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.kMediumBorderRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Glass.dialogBg(context),
                borderRadius: BorderRadius.circular(
                  AppColors.kMediumBorderRadius,
                ),
                border: Border.all(color: Glass.border(context), width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    content,
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (showDefaultCancel)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              cancelLabel,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        if (actions != null) ...actions,
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
  State<_TextInputDialogContent> createState() =>
      _TextInputDialogContentState();
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
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.kMediumBorderRadius),
          boxShadow: AppColors.shadowLevel4,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.kMediumBorderRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Glass.dialogBg(context),
                borderRadius: BorderRadius.circular(
                  AppColors.kMediumBorderRadius,
                ),
                border: Border.all(color: Glass.border(context), width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: true,
                      controller: _controller,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            widget.cancelLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () =>
                              Navigator.pop(context, _controller.text),
                          child: Text(widget.confirmLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
