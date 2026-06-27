import 'package:flutter/material.dart';
import 'responsive.dart';

/// 响应式布局构建器，根据屏幕类型显示不同的 Widget
///
/// 使用示例：
/// ```dart
/// ResponsiveLayoutBuilder(
///   phone: (context, type) => PhoneLayout(),
///   tablet: (context, type) => TabletLayout(),
///   desktop: (context, type) => DesktopLayout(),
/// )
/// ```
class ResponsiveLayoutBuilder extends StatelessWidget {
  /// 手机布局构建器（必须）
  final Widget Function(BuildContext context, ScreenType screenType) phone;

  /// 平板布局构建器（可选，默认使用 phone）
  final Widget Function(BuildContext context, ScreenType screenType)? tablet;

  /// 桌面布局构建器（可选，默认使用 tablet 或 phone）
  final Widget Function(BuildContext context, ScreenType screenType)? desktop;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    switch (screenType) {
      case ScreenType.phone:
        return phone(context, screenType);
      case ScreenType.tablet:
        return tablet?.call(context, screenType) ?? phone(context, screenType);
      case ScreenType.desktop:
        return desktop?.call(context, screenType) ??
            tablet?.call(context, screenType) ??
            phone(context, screenType);
    }
  }
}

/// 条件响应式布局构建器
///
/// 当条件满足时显示一个 Widget，否则显示另一个
///
/// 使用示例：
/// ```dart
/// ConditionalResponsiveLayout(
///   condition: ResponsiveUtils.isPhone(context),
///   phone: PhoneLayout(),
///   other: TabletLayout(),
/// )
/// ```
class ConditionalResponsiveLayout extends StatelessWidget {
  final bool condition;
  final Widget phone;
  final Widget other;

  const ConditionalResponsiveLayout({
    super.key,
    required this.condition,
    required this.phone,
    required this.other,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? phone : other;
  }
}

/// 响应式容器，根据屏幕类型自动调整宽度约束
///
/// 使用示例：
/// ```dart
/// ResponsiveContainer(
///   phone: (context) => SizedBox.expand(),
///   tablet: (context) => SizedBox(width: 600, child: content),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  final Widget Function(BuildContext context)? phone;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveContainer({super.key, this.phone, this.tablet, this.desktop});

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    switch (screenType) {
      case ScreenType.phone:
        return phone?.call(context) ?? const SizedBox.shrink();
      case ScreenType.tablet:
        return tablet?.call(context) ??
            phone?.call(context) ??
            const SizedBox.shrink();
      case ScreenType.desktop:
        return desktop?.call(context) ??
            tablet?.call(context) ??
            phone?.call(context) ??
            const SizedBox.shrink();
    }
  }
}
