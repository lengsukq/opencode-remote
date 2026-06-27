import 'package:flutter/material.dart';
import '../strings.dart';
import '../theme.dart';
import 'app_dialog.dart';

/// Shows a dialog for entering a shell command.
///
/// Returns the command string, or `null` if cancelled.
Future<String?> showShellDialog(BuildContext context) {
  return AppDialog.showCustom<String>(
    context,
    title: S.runShellCommand,
    showDefaultCancel: true,
    cancelLabel: S.cancel,
    content: Builder(
      builder: (ctx) => TextField(
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'ls -la',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderFocused),
          ),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
    ),
    actions: [
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        onPressed: () => Navigator.pop(context, ''),
        child: Text(S.ok),
      ),
    ],
  );
}
