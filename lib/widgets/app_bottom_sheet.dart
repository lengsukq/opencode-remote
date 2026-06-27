import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/glass_effect.dart';

/// Shared bottom sheet helpers for consistent iOS-style modal bottom sheet styling.
///
/// Uses [GlassSheet] for the glassmorphism effect with large top rounded corners
/// (16px), 3D shadows (level 4), and an iOS-style drag indicator pill.
///
/// Usage:
/// ```dart
/// final result = await AppBottomSheet.show(context, child: myWidget);
///
/// final selected = await AppBottomSheet.showOptions(context,
///   title: '选择操作',
///   options: [
///     BottomSheetOption(icon: Icons.edit, label: '编辑', value: 'edit'),
///   ],
/// );
/// ```
class AppBottomSheet {
  AppBottomSheet._();

  /// Shows a modal bottom sheet with iOS-style glassmorphism.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double borderRadius = AppColors.kDefaultBorderRadius,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => _buildSheet(borderRadius: borderRadius, child: child),
    );
  }

  /// Shows a bottom sheet with a title and a list of options.
  ///
  /// Each option is rendered as a [ListTile]. Returns the value of the
  /// selected option, or null if dismissed.
  static Future<T?> showOptions<T>(
    BuildContext context, {
    required String title,
    required List<BottomSheetOption<T>> options,
    double borderRadius = AppColors.kDefaultBorderRadius,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => _buildSheet(
        borderRadius: borderRadius,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragIndicator(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              ...options.map(
                (opt) => ListTile(
                  leading: Icon(
                    opt.icon,
                    color: opt.iconColor ?? AppColors.textSecondary,
                  ),
                  title: Text(
                    opt.label,
                    style: TextStyle(
                      color: opt.destructive
                          ? AppColors.danger
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, opt.value),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSheet({
    required double borderRadius,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: AppColors.shadowLevel4),
      child: GlassSheet(
        borderRadius: borderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const _DragIndicator(), child],
        ),
      ),
    );
  }
}

/// iOS-style drag indicator pill at the top of a bottom sheet.
class _DragIndicator extends StatelessWidget {
  const _DragIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.textTertiary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }
}

/// An option for [AppBottomSheet.showOptions].
class BottomSheetOption<T> {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final T value;
  final bool destructive;

  const BottomSheetOption({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.value,
    this.destructive = false,
  });
}
