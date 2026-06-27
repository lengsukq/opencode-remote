import 'package:flutter/material.dart';
import 'responsive.dart';

/// 响应式数值工具类，根据设备类型返回不同尺寸
///
/// 使用示例：
/// ```dart
/// // 简单使用
/// final padding = R.padding(context);
/// final fontSize = R.fontSize(context);
///
/// // 自定义值
/// final padding = R.value(context, phone: 16, tablet: 20, desktop: 24);
/// ```
class R {
  /// 根据设备类型返回不同的数值
  static double value(
    BuildContext context, {
    required double phone,
    double? tablet,
    double? desktop,
  }) {
    final screenType = ResponsiveUtils.getScreenType(context);
    switch (screenType) {
      case ScreenType.phone:
        return phone;
      case ScreenType.tablet:
        return tablet ?? phone;
      case ScreenType.desktop:
        return desktop ?? tablet ?? phone;
    }
  }

  /// 根据设备类型返回不同的整数值
  static int intValue(
    BuildContext context, {
    required int phone,
    int? tablet,
    int? desktop,
  }) {
    return value(
      context,
      phone: phone.toDouble(),
      tablet: tablet?.toDouble(),
      desktop: desktop?.toDouble(),
    ).toInt();
  }

  /// 根据设备类型返回不同的 EdgeInsets
  static EdgeInsets edgeInsets(
    BuildContext context, {
    required EdgeInsets phone,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    final screenType = ResponsiveUtils.getScreenType(context);
    switch (screenType) {
      case ScreenType.phone:
        return phone;
      case ScreenType.tablet:
        return tablet ?? phone;
      case ScreenType.desktop:
        return desktop ?? tablet ?? phone;
    }
  }

  /// 根据设备类型返回不同的 Size
  static Size size(
    BuildContext context, {
    required Size phone,
    Size? tablet,
    Size? desktop,
  }) {
    final screenType = ResponsiveUtils.getScreenType(context);
    switch (screenType) {
      case ScreenType.phone:
        return phone;
      case ScreenType.tablet:
        return tablet ?? phone;
      case ScreenType.desktop:
        return desktop ?? tablet ?? phone;
    }
  }

  // ==================== 便捷方法 ====================

  /// 屏幕内边距（根据设备类型自动调整）
  static EdgeInsets screenPadding(BuildContext context) {
    return edgeInsets(
      context,
      phone: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(20),
      desktop: const EdgeInsets.all(24),
    );
  }

  /// 卡片内边距（根据设备类型自动调整）
  static EdgeInsets cardPadding(BuildContext context) {
    return edgeInsets(
      context,
      phone: const EdgeInsets.all(14),
      tablet: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(18),
    );
  }

  /// 列表内边距（根据设备类型自动调整）
  static EdgeInsets listPadding(BuildContext context) {
    return edgeInsets(
      context,
      phone: const EdgeInsets.all(12),
      tablet: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(20),
    );
  }

  /// 对话框内边距（根据设备类型自动调整）
  static EdgeInsets dialogPadding(BuildContext context) {
    return edgeInsets(
      context,
      phone: const EdgeInsets.all(20),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(28),
    );
  }

  /// 输入框内边距（根据设备类型自动调整）
  static EdgeInsets inputPadding(BuildContext context) {
    return edgeInsets(
      context,
      phone: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }

  /// 标题字体大小（根据设备类型自动调整）
  static double titleFontSize(BuildContext context) {
    return value(context, phone: 18, tablet: 20, desktop: 22);
  }

  /// 副标题字体大小（根据设备类型自动调整）
  static double subtitleFontSize(BuildContext context) {
    return value(context, phone: 14, tablet: 15, desktop: 16);
  }

  /// 正文字体大小（根据设备类型自动调整）
  static double bodyFontSize(BuildContext context) {
    return value(context, phone: 14, tablet: 15, desktop: 16);
  }

  /// 小字体大小（根据设备类型自动调整）
  static double smallFontSize(BuildContext context) {
    return value(context, phone: 12, tablet: 13, desktop: 14);
  }

  /// 标签字体大小（根据设备类型自动调整）
  static double labelFontSize(BuildContext context) {
    return value(context, phone: 11, tablet: 12, desktop: 13);
  }

  /// 图标大小（根据设备类型自动调整）
  static double iconSize(BuildContext context) {
    return value(context, phone: 20, tablet: 22, desktop: 24);
  }

  /// 小图标大小（根据设备类型自动调整）
  static double smallIconSize(BuildContext context) {
    return value(context, phone: 16, tablet: 18, desktop: 20);
  }

  /// 标准间距（根据设备类型自动调整）
  static double spacing(BuildContext context) {
    return value(context, phone: 12, tablet: 14, desktop: 16);
  }

  /// 小间距（根据设备类型自动调整）
  static double smallSpacing(BuildContext context) {
    return value(context, phone: 6, tablet: 8, desktop: 10);
  }

  /// 中等间距（根据设备类型自动调整）
  static double mediumSpacing(BuildContext context) {
    return value(context, phone: 16, tablet: 20, desktop: 24);
  }

  /// 大间距（根据设备类型自动调整）
  static double largeSpacing(BuildContext context) {
    return value(context, phone: 24, tablet: 32, desktop: 40);
  }

  /// 圆角半径（根据设备类型自动调整）
  static double borderRadius(BuildContext context) {
    return value(context, phone: 12, tablet: 14, desktop: 16);
  }

  /// 小圆角半径（根据设备类型自动调整）
  static double smallBorderRadius(BuildContext context) {
    return value(context, phone: 8, tablet: 10, desktop: 12);
  }

  /// 网格列数（根据设备类型自动调整）
  static int gridColumns(BuildContext context) {
    return intValue(context, phone: 2, tablet: 3, desktop: 4);
  }

  /// 卡片最大宽度（根据设备类型自动调整）
  static double cardMaxWidth(BuildContext context) {
    return value(context, phone: double.infinity, tablet: 400, desktop: 450);
  }

  /// 内容最大宽度（根据设备类型自动调整）
  static double contentMaxWidth(BuildContext context) {
    return value(context, phone: double.infinity, tablet: 600, desktop: 800);
  }

  /// 树状视图缩进（根据设备类型自动调整）
  static double treeIndent(BuildContext context) {
    return value(context, phone: 20, tablet: 24, desktop: 28);
  }

  /// 终端字体大小（根据设备类型自动调整）
  static double terminalFontSize(BuildContext context) {
    return value(context, phone: 13, tablet: 14, desktop: 15);
  }

  /// 消息气泡最大宽度比例（根据设备类型自动调整）
  static double messageBubbleWidthRatio(BuildContext context) {
    return value(context, phone: 0.85, tablet: 0.75, desktop: 0.7);
  }

  /// 底部导航栏高度（根据设备类型自动调整）
  static double bottomNavBarHeight(BuildContext context) {
    return value(context, phone: 60, tablet: 65, desktop: 70);
  }

  /// 导航栏宽度（根据设备类型自动调整）
  static double navRailWidth(BuildContext context) {
    return value(context, phone: 72, tablet: 80, desktop: 88);
  }

  /// AppBar 高度（根据设备类型自动调整）
  static double appBarHeight(BuildContext context) {
    return value(context, phone: 56, tablet: 60, desktop: 64);
  }

  /// 底部安全区域高度
  static double bottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 顶部安全区域高度
  static double topSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
}
