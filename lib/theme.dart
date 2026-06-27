import 'package:flutter/material.dart';

/// Returns true if the current app theme is dark mode.
bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

class AppColors {
  AppColors._();

  // Light mode (used by default, Material dark theme handles its own)
  static const background = Color(0xFFF5F5F7);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF0F0F3);
  static const border = Color(0xFFE5E5EA);
  static const borderFocused = Color(0xFF6366F1);

  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFFEEF0FF);

  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFFC7C7CC);

  static const success = Color(0xFF34C759);
  static const successLight = Color(0xFFE8F5E9);
  static const danger = Color(0xFFFF3B30);
  static const warning = Color(0xFFFF9500);
  static const info = Color(0xFF007AFF);

  static const shadow = Color(0x1A000000);
  static const shadowStrong = Color(0x26000000);

  // 尺寸常量
  static const double kDefaultBorderRadius = 16;
  static const double kCardBorderRadius = 12;
  static const double kSmallBorderRadius = 8;
  static const double kChipBorderRadius = 6;
  static const double kMediumBorderRadius = 20;

  // 间距常量
  static const EdgeInsets kPaddingScreen = EdgeInsets.all(16);
  static const EdgeInsets kPaddingCard = EdgeInsets.all(14);
  static const EdgeInsets kPaddingInput = EdgeInsets.symmetric(horizontal: 16, vertical: 10);

  // Project avatar colors
  static const avatarBg = Color(0xFFE8E8ED);
  static const avatarText = Color(0xFF636366);

  // Terminal colors
  static const terminalBg = Color(0xFF1A1A1A);
  static const terminalText = Color(0xFFD4D4D4);
  static const terminalBgLight = Color(0xFF1E1E1E);
  static const terminalTextLight = Color(0xFFCCCCCC);
  static const terminalInput = Color(0xFF98C379);
  static const terminalError = Color(0xFFE06C75);
  static const terminalPrompt = Color(0xFF61AFEF);
  static const terminalIcon = Color(0xFF888888);
  static const terminalInputBg = Color(0xFF252526);

  // Overlay colors for image/text overlays
  static const overlayDark = Color(0xDD000000);
}

class DarkColors {
  DarkColors._();

  static const background = Color(0xFF1C1C1E);
  static const surface = Color(0xFF2C2C2E);
  static const surfaceAlt = Color(0xFF3A3A3C);
  static const border = Color(0xFF48484A);
  static const borderFocused = Color(0xFF818CF8);

  static const primary = Color(0xFF818CF8);
  static const primaryLight = Color(0xFF1E1B4B);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFA1A1A6);
  static const textTertiary = Color(0xFF636366);

  static const success = Color(0xFF30D158);
  static const danger = Color(0xFFFF453A);
  static const warning = Color(0xFFFF9F0A);
  static const info = Color(0xFF0A84FF);

  static const shadow = Color(0x33000000);
  static const shadowStrong = Color(0x4C000000);

  // Project avatar colors
  static const avatarBg = Color(0xFF3A3A3C);
  static const avatarText = Color(0xFFA1A1A6);

  // Terminal colors
  static const terminalBg = Color(0xFF1A1A1A);
  static const terminalText = Color(0xFFD4D4D4);
  static const terminalInput = Color(0xFF98C379);
  static const terminalError = Color(0xFFE06C75);
  static const terminalPrompt = Color(0xFF61AFEF);
  static const terminalIcon = Color(0xFF888888);
  static const terminalInputBg = Color(0xFF252526);
}

/// 响应式主题工具类
///
/// 提供基于设备类型的响应式主题值
class ResponsiveTheme {
  ResponsiveTheme._();

  /// 获取响应式的圆角半径
  static double getBorderRadius(BuildContext context, {String size = 'default'}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;

    switch (size) {
      case 'small':
        return isPhone ? 8 : 10;
      case 'medium':
        return isPhone ? 12 : 14;
      case 'large':
        return isPhone ? 16 : 20;
      default:
        return isPhone ? 12 : 14;
    }
  }

  /// 获取响应式的阴影
  static List<BoxShadow> getShadow(BuildContext context, {String size = 'default'}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;

    switch (size) {
      case 'small':
        return [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: isPhone ? 4 : 6,
            offset: Offset(0, isPhone ? 1 : 2),
          ),
        ];
      case 'large':
        return [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: isPhone ? 12 : 16,
            offset: Offset(0, isPhone ? 4 : 6),
          ),
        ];
      default:
        return [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: isPhone ? 8 : 10,
            offset: Offset(0, isPhone ? 2 : 3),
          ),
        ];
    }
  }

  /// 获取响应式的边框
  static Border getBorder(BuildContext context, {Color? color}) {
    return Border.all(
      color: color ?? AppColors.border,
      width: 1,
    );
  }

  /// 获取响应式的内边距
  static EdgeInsets getPadding(BuildContext context, {String size = 'default'}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;

    switch (size) {
      case 'small':
        return EdgeInsets.all(isPhone ? 8 : 12);
      case 'medium':
        return EdgeInsets.all(isPhone ? 12 : 16);
      case 'large':
        return EdgeInsets.all(isPhone ? 16 : 20);
      default:
        return EdgeInsets.all(isPhone ? 12 : 14);
    }
  }

  /// 获取响应式的字体大小
  static double getFontSize(BuildContext context, {String size = 'body'}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;

    switch (size) {
      case 'caption':
        return isPhone ? 10 : 11;
      case 'small':
        return isPhone ? 11 : 12;
      case 'body':
        return isPhone ? 13 : 14;
      case 'subtitle':
        return isPhone ? 14 : 15;
      case 'title':
        return isPhone ? 16 : 18;
      case 'headline':
        return isPhone ? 20 : 24;
      default:
        return isPhone ? 13 : 14;
    }
  }
}
