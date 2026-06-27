import 'package:flutter/material.dart';

/// Returns true if the current app theme is dark mode.
bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

/// iOS 风格色彩体系
///
/// 灵感来自 iOS 17/18 的设计语言，提供：
/// - 柔和的毛玻璃半透明色
/// - 大圆角（16-24px）
/// - 3D 阴影层级
/// - 自适应亮色/暗色
class AppColors {
  AppColors._();

  // ==================== 基础色 ====================
  static const background = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F0F3);

  // ==================== iOS 系统色 ====================
  static const primary = Color(0xFF007AFF); // iOS Blue
  static const primaryLight = Color(0xFFE8F0FE);

  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFFC7C7CC);

  static const success = Color(0xFF34C759); // iOS Green
  static const successLight = Color(0xFFE8F5E9);
  static const danger = Color(0xFFFF3B30); // iOS Red
  static const warning = Color(0xFFFF9500); // iOS Orange
  static const info = Color(0xFF5AC8FA); // iOS Light Blue

  // ==================== 边框色 ====================
  static const border = Color(0xFFE5E5EA);
  static const borderFocused = Color(0xFF007AFF);

  // ==================== 3D 阴影层级 ====================
  // 使用多层阴影模拟 iOS 风格的 3D 深度感

  /// 最浅阴影 - 用于按钮等小元素
  static List<BoxShadow> get shadowLevel1 => const [
    BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// 浅阴影 - 用于卡片
  static List<BoxShadow> get shadowLevel2 => const [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: -1,
    ),
    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// 中阴影 - 用于浮层卡片
  static List<BoxShadow> get shadowLevel3 => const [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -3,
    ),
    BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// 深阴影 - 用于对话框、底部面板
  static List<BoxShadow> get shadowLevel4 => const [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 32,
      offset: Offset(0, 16),
      spreadRadius: -6,
    ),
    BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ==================== 大圆角常量 ====================
  static const double kDefaultBorderRadius = 16;
  static const double kCardBorderRadius = 14;
  static const double kSmallBorderRadius = 10;
  static const double kChipBorderRadius = 8;
  static const double kMediumBorderRadius = 20;
  static const double kLargeBorderRadius = 24;

  // ==================== 间距常量 ====================
  static const EdgeInsets kPaddingScreen = EdgeInsets.all(16);
  static const EdgeInsets kPaddingCard = EdgeInsets.all(14);
  static const EdgeInsets kPaddingInput = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );
  static const EdgeInsets kPaddingSection = EdgeInsets.fromLTRB(16, 20, 16, 8);

  // ==================== 其他 ====================
  static const avatarBg = Color(0xFFE8E8ED);
  static const avatarText = Color(0xFF636366);

  // Terminal colors
  static const terminalBg = Color(0xFF1C1C1E);
  static const terminalText = Color(0xFFD4D4D4);
  static const terminalBgLight = Color(0xFF1E1E1E);
  static const terminalTextLight = Color(0xFFCCCCCC);
  static const terminalInput = Color(0xFF98C379);
  static const terminalError = Color(0xFFE06C75);
  static const terminalPrompt = Color(0xFF61AFEF);
  static const terminalIcon = Color(0xFF888888);
  static const terminalInputBg = Color(0xFF252526);
}

/// 暗色模式 iOS 色彩体系
class DarkColors {
  DarkColors._();

  // ==================== 基础色 ====================
  static const background = Color(0xFF1C1C1E);
  static const surface = Color(0xFF2C2C2E);
  static const surfaceAlt = Color(0xFF3A3A3C);

  // ==================== iOS 暗色系统色 ====================
  static const primary = Color(0xFF0A84FF); // iOS Dark Blue
  static const primaryLight = Color(0xFF1E1B4B);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFA1A1A6);
  static const textTertiary = Color(0xFF636366);

  static const success = Color(0xFF30D158); // iOS Dark Green
  static const danger = Color(0xFFFF453A); // iOS Dark Red
  static const warning = Color(0xFFFF9F0A); // iOS Dark Orange
  static const info = Color(0xFF64D2FF); // iOS Dark Light Blue

  // ==================== 边框色 ====================
  static const border = Color(0xFF38383A);
  static const borderFocused = Color(0xFF0A84FF);

  // ==================== 3D 阴影层级（暗色更强） ====================
  static List<BoxShadow> get shadowLevel1 => const [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> get shadowLevel2 => const [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: -1,
    ),
    BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> get shadowLevel3 => const [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -3,
    ),
    BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static List<BoxShadow> get shadowLevel4 => const [
    BoxShadow(
      color: Color(0x4C000000),
      blurRadius: 32,
      offset: Offset(0, 16),
      spreadRadius: -6,
    ),
    BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ==================== 其他 ====================
  static const avatarBg = Color(0xFF3A3A3C);
  static const avatarText = Color(0xFFA1A1A6);

  // Terminal colors
  static const terminalBg = Color(0xFF1C1C1E);
  static const terminalText = Color(0xFFD4D4D4);
  static const terminalInput = Color(0xFF98C379);
  static const terminalError = Color(0xFFE06C75);
  static const terminalPrompt = Color(0xFF61AFEF);
  static const terminalIcon = Color(0xFF888888);
  static const terminalInputBg = Color(0xFF252526);
}

/// 响应式主题工具 - 提供 iOS 风格的响应式设计值
class ResponsiveTheme {
  ResponsiveTheme._();

  /// 获取 3D 阴影层级
  static List<BoxShadow> getShadow(BuildContext context, {int level = 2}) {
    final isDark = isDarkMode(context);
    switch (level) {
      case 1:
        return isDark ? DarkColors.shadowLevel1 : AppColors.shadowLevel1;
      case 3:
        return isDark ? DarkColors.shadowLevel3 : AppColors.shadowLevel3;
      case 4:
        return isDark ? DarkColors.shadowLevel4 : AppColors.shadowLevel4;
      default:
        return isDark ? DarkColors.shadowLevel2 : AppColors.shadowLevel2;
    }
  }

  /// 获取响应式圆角
  static double getBorderRadius(
    BuildContext context, {
    String size = 'default',
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;

    switch (size) {
      case 'small':
        return isPhone ? 10 : 12;
      case 'medium':
        return isPhone ? 14 : 16;
      case 'large':
        return isPhone ? 20 : 24;
      default:
        return isPhone ? 14 : 16;
    }
  }

  /// 获取响应式内边距
  static EdgeInsets getPadding(
    BuildContext context, {
    String size = 'default',
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;

    switch (size) {
      case 'small':
        return EdgeInsets.all(isPhone ? 10 : 12);
      case 'medium':
        return EdgeInsets.all(isPhone ? 14 : 16);
      case 'large':
        return EdgeInsets.all(isPhone ? 18 : 24);
      default:
        return EdgeInsets.all(isPhone ? 14 : 16);
    }
  }

  /// 获取响应式字体大小
  static double getFontSize(BuildContext context, {String size = 'body'}) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;

    switch (size) {
      case 'caption':
        return isPhone ? 11 : 12;
      case 'small':
        return isPhone ? 12 : 13;
      case 'body':
        return isPhone ? 14 : 15;
      case 'subtitle':
        return isPhone ? 15 : 17;
      case 'title':
        return isPhone ? 17 : 20;
      case 'headline':
        return isPhone ? 22 : 28;
      default:
        return isPhone ? 14 : 15;
    }
  }
}

/// 生成 iOS 风格的 Material 主题
class IOSTheme {
  IOSTheme._();

  /// 亮色主题
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // iOS 风格 NavigationBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 卡片
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),

      // 按钮
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // 底部导航栏
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // 底部面板
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),

      // 对话框
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // 分割线
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0.5,
      ),

      // 弹出菜单
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // 滚动条
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(6),
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(
          AppColors.textTertiary.withValues(alpha: 0.5),
        ),
      ),

      // 悬浮按钮
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // 滑块
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
        thumbColor: Colors.white,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      // 开关
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // 进度条
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primary.withValues(alpha: 0.15),
        circularTrackColor: AppColors.primary.withValues(alpha: 0.15),
      ),

      // 图标
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),

      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.primary.withValues(alpha: 0.04),
      focusColor: AppColors.primary.withValues(alpha: 0.08),
    );
  }

  /// 暗色主题
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: DarkColors.primary,
      secondary: DarkColors.primary,
      surface: DarkColors.surface,
      error: DarkColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: DarkColors.textPrimary,
      onError: Colors.white,
      outline: DarkColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DarkColors.textPrimary,
        titleTextStyle: TextStyle(
          color: DarkColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: DarkColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DarkColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DarkColors.danger, width: 1),
        ),
        hintStyle: const TextStyle(
          color: DarkColors.textTertiary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: DarkColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DarkColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DarkColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: DarkColors.primary,
        unselectedItemColor: DarkColors.textTertiary,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      dividerTheme: const DividerThemeData(
        color: DarkColors.border,
        thickness: 0.5,
        space: 0.5,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: DarkColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: DarkColors.textPrimary,
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: DarkColors.textSecondary,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: DarkColors.primary,
        unselectedLabelColor: DarkColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(6),
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(
          DarkColors.textTertiary.withValues(alpha: 0.5),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DarkColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: DarkColors.primary,
        inactiveTrackColor: DarkColors.primary.withValues(alpha: 0.2),
        thumbColor: Colors.white,
        overlayColor: DarkColors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return DarkColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DarkColors.primary;
          return DarkColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: DarkColors.primary,
        linearTrackColor: DarkColors.primary.withValues(alpha: 0.15),
        circularTrackColor: DarkColors.primary.withValues(alpha: 0.15),
      ),

      iconTheme: const IconThemeData(color: DarkColors.textSecondary, size: 22),

      scaffoldBackgroundColor: DarkColors.background,
      canvasColor: DarkColors.background,
      dividerColor: DarkColors.border,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: DarkColors.primary.withValues(alpha: 0.04),
      focusColor: DarkColors.primary.withValues(alpha: 0.08),
    );
  }
}
