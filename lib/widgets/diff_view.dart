import 'package:flutter/material.dart';
import '../theme.dart';

class DiffView extends StatelessWidget {
  final String filePath;
  final String status;
  final List<DiffHunkView> hunks;

  const DiffView({
    super.key,
    required this.filePath,
    required this.status,
    required this.hunks,
  });

  IconData get _statusIcon {
    switch (status) {
      case 'added':
        return Icons.add_circle;
      case 'deleted':
        return Icons.remove_circle;
      default:
        return Icons.edit;
    }
  }

  Color get _statusColor {
    switch (status) {
      case 'added':
        return AppColors.success;
      case 'deleted':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  int get totalAdditions => hunks.fold(0, (sum, h) => sum + h.additions);
  int get totalDeletions => hunks.fold(0, (sum, h) => sum + h.deletions);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          ...hunks.map((h) => _HunkView(hunk: h)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          Icon(_statusIcon, color: _statusColor, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              filePath,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (totalAdditions > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '+$totalAdditions',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (totalDeletions > 0) const SizedBox(width: 4),
          if (totalDeletions > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '-$totalDeletions',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DiffHunkView {
  final int oldStart;
  final int newStart;
  final String content;
  final int additions;
  final int deletions;

  DiffHunkView({
    required this.oldStart,
    required this.newStart,
    required this.content,
    required this.additions,
    required this.deletions,
  });

  DiffHunkView.fromContent(this.oldStart, this.newStart, this.content)
    : additions = '\n$content'
          .split('\n')
          .where((l) => l.startsWith('+'))
          .length,
      deletions = '\n$content'
          .split('\n')
          .where((l) => l.startsWith('-'))
          .length;
}

class _HunkView extends StatelessWidget {
  final DiffHunkView hunk;

  const _HunkView({required this.hunk});

  @override
  Widget build(BuildContext context) {
    final lines = hunk.content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          color: AppColors.border.withValues(alpha: 0.3),
          child: Text(
            '@@ -${hunk.oldStart} +${hunk.newStart} @@',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
        ...lines.map((line) {
          if (line.startsWith('+')) {
            return _diffLine(
              line,
              AppColors.success.withValues(alpha: 0.15),
              '+',
            );
          } else if (line.startsWith('-')) {
            return _diffLine(
              line,
              AppColors.danger.withValues(alpha: 0.15),
              '-',
            );
          } else {
            return _diffLine(line, Colors.transparent, ' ');
          }
        }),
      ],
    );
  }

  Widget _diffLine(String line, Color bgColor, String prefix) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 1, bottom: 1),
      color: bgColor,
      child: Text(
        '$prefix${line.isNotEmpty ? line.substring(1) : ''}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
