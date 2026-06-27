import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme.dart';

/// A full-screen dialog with iOS-style blurred background and close button.
///
/// Used for file content previews, image previews, and other
/// content that needs a closeable full-screen presentation.
///
/// Usage:
/// ```dart
/// AppFullScreenDialog(
///   title: '文件名',
///   child: SingleChildScrollView(
///     child: SelectableText(content),
///   ),
/// )
/// ```
class AppFullScreenDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expandContent;

  const AppFullScreenDialog({
    super.key,
    required this.title,
    required this.child,
    this.expandContent = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget child,
    bool expandContent = true,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.kMediumBorderRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
              decoration: BoxDecoration(
                color: _glassBg(context),
                borderRadius: BorderRadius.circular(
                  AppColors.kMediumBorderRadius,
                ),
                border: Border.all(color: _glassBorder(context), width: 0.5),
              ),
              child: Column(
                mainAxisSize: expandContent
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    title: Text(title),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  if (expandContent) Expanded(child: child) else child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _glassBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.92)
        : const Color(0xFFF9F9FA).withValues(alpha: 0.92);
  }

  static Color _glassBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.50);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
