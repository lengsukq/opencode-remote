import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_card.dart';

/// A selectable tile with optional border highlight and check indicator.
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
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final bgColor = selected ? AppColors.primaryLight : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: AppColors.kPaddingCard,
        borderColor: borderColor,
        color: bgColor,
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
