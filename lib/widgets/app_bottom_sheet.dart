import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared bottom sheet helpers for consistent modal bottom sheet styling.
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

  /// Shows a modal bottom sheet with standard theming.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double borderRadius = AppColors.kDefaultBorderRadius,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      builder: (_) => child,
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
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(),
            ...options.map((opt) => ListTile(
              leading: Icon(opt.icon, color: opt.iconColor ?? AppColors.textSecondary),
              title: Text(
                opt.label,
                style: TextStyle(
                  color: opt.destructive ? AppColors.danger : AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.pop(ctx, opt.value),
            )),
            const SizedBox(height: 8),
          ],
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
