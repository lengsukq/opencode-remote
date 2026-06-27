import 'package:flutter/material.dart';

/// 设备类型枚举
enum ScreenType { phone, tablet, desktop }

/// 响应式工具类，用于获取设备类型和屏幕尺寸
class ResponsiveUtils {
  /// 手机断点（宽度小于此值）
  static const double phoneBreakpoint = 600;

  /// 平板断点（宽度小于此值）
  static const double tabletBreakpoint = 900;

  /// 获取当前屏幕类型
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < phoneBreakpoint) return ScreenType.phone;
    if (width < tabletBreakpoint) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  /// 判断是否为手机屏幕
  static bool isPhone(BuildContext context) {
    return getScreenType(context) == ScreenType.phone;
  }

  /// 判断是否为平板屏幕
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  /// 判断是否为桌面屏幕
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.desktop;
  }

  /// 判断是否为平板或桌面屏幕
  static bool isTabletOrDesktop(BuildContext context) {
    return !isPhone(context);
  }

  /// 获取屏幕宽度
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// 获取屏幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// 获取屏幕方向
  static Orientation orientation(BuildContext context) {
    return MediaQuery.orientationOf(context);
  }

  /// 判断是否为横屏
  static bool isLandscape(BuildContext context) {
    return orientation(context) == Orientation.landscape;
  }

  /// 判断是否为竖屏
  static bool isPortrait(BuildContext context) {
    return orientation(context) == Orientation.portrait;
  }
}
