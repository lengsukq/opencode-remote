import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared widgets for common UI states: loading, empty, and error.
///
/// Usage:
/// ```dart
/// if (_loading) return const AppLoadingIndicator();
/// if (_error != null) return AppErrorState(message: _error!, onRetry: _load);
/// if (_items.isEmpty) return const AppEmptyState(icon: Icons.inbox, title: '暂无数据');
/// ```
class AppStates {
  AppStates._();
}

/// A centered loading indicator using the app's primary color.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

/// A centered empty state with icon, title, and optional subtitle.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// A centered error state with message, optional detail, and retry button.
class AppErrorState extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text(
              '连接失败',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small colored badge/label with optional icon.
///
/// Used for status indicators, diff counts, and tool status.
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double fontSize;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
