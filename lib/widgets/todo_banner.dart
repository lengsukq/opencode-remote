import 'package:flutter/material.dart';
import '../../theme.dart';

/// Banner showing todo completion progress.
class TodoBanner extends StatelessWidget {
  final int done;
  final int total;

  const TodoBanner({super.key, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.checklist, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pct >= 1.0 ? 'All todos completed!' : '$done/$total done',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          if (pct < 1.0)
            LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              color: AppColors.success,
              minHeight: 4,
            ),
          if (pct >= 1.0)
            const Icon(Icons.check_circle, size: 16, color: AppColors.success),
        ],
      ),
    );
  }
}
