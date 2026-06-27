import 'package:flutter/material.dart';
import '../strings.dart';
import '../theme.dart';

/// Shows a dialog asking for a file path to apply code to.
///
/// Returns the file path if the user taps "Write", or `null` if cancelled.
Future<String?> showApplyCodeDialog(
  BuildContext context, {
  required String code,
  String? language,
}) {
  final pathCtrl = TextEditingController(
    text: language != null && language != 'plaintext'
        ? 'main.$language'
        : 'output.txt',
  );

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        S.applyCodeToFile,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write the following code to file:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              code.length > 200
                  ? '${code.substring(0, 200)}...'
                  : code,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pathCtrl,
            autofocus: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              labelText: 'File Path',
              hintText: 'lib/main.dart',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintStyle: TextStyle(color: AppColors.textTertiary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.borderFocused),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () {
            final path = pathCtrl.text.trim();
            if (path.isEmpty) return;
            Navigator.pop(ctx, path);
          },
          child: const Text('Write'),
        ),
      ],
    ),
  );
}
