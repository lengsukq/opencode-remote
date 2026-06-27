import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/glass_effect.dart';

/// A selectable tile with iOS-style glassmorphism and selection indicator.
///
/// Uses [GlassCard] as the base with large rounded corners. When selected,
/// a check circle icon and primary color border indicate the active state.
///
/// Used for mode/theme selection in settings and onboarding screens.
///
/// Usage:
/// ```dart
/// AppSelectableTile(
///   icon: Icons.light_mode,
///   title: '浅色',
///   subtitle: '浅色主题',
///   selected: true,
///   onTap: () {},
/// )
/// ```
class AppSelectableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const AppSelectableTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = selected
        ? (isDark ? DarkColors.primaryLight : AppColors.primaryLight)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: AppColors.kDefaultBorderRadius,
        padding: AppColors.kPaddingCard,
        foregroundColor: bgColor,
        boxShadow: selected ? AppColors.shadowLevel2 : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
