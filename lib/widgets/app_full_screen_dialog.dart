import 'package:flutter/material.dart';
import '../theme.dart';

/// A full-screen dialog with AppBar header and close button.
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
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        child: Column(
          mainAxisSize: expandContent ? MainAxisSize.max : MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            if (expandContent)
              Expanded(child: child)
            else
              child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
