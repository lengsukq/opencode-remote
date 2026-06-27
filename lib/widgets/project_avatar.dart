import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

class ProjectAvatar extends StatelessWidget {
  final Project project;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? currentBranch;

  const ProjectAvatar({
    super.key,
    required this.project,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
    this.currentBranch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final bgColor = isDark ? DarkColors.avatarBg : AppColors.avatarBg;
    final textColor = isDark ? DarkColors.avatarText : AppColors.avatarText;
    final initials = project.name.length >= 2
        ? project.name.substring(0, 2).toUpperCase()
        : project.name.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: project.name,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primaryLight : bgColor,
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: isActive ? AppColors.primary : textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (currentBranch != null && currentBranch!.isNotEmpty)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 60),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DarkColors.surfaceAlt
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? DarkColors.border : AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        currentBranch!,
                        style: TextStyle(
                          fontSize: 8,
                          color: isDark
                              ? DarkColors.textSecondary
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
