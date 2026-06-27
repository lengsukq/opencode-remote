import 'package:flutter/material.dart';
import '../../theme.dart';

/// Banner shown when a message has been reverted.
class RevertBanner extends StatelessWidget {
  final VoidCallback onRestore;

  const RevertBanner({super.key, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.undo, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Message reverted',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRestore,
            child: const Text(
              'Restore',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
