import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 毛玻璃效果（Glassmorphism）工具集
///
/// 提供 iOS 风格的毛玻璃背景、卡片、导航栏等组件
class Glass {
  Glass._();

  /// 默认毛玻璃模糊强度
  static const double defaultBlur = 24;

  /// 导航栏模糊强度（略轻，保持文字清晰）
  static const double navBlur = 30;

  /// 卡片模糊强度
  static const double cardBlur = 20;

  /// 对话框模糊强度
  static const double dialogBlur = 40;

  // ==================== 背景色（亮色模式） ====================

  /// 亮色模式 - 毛玻璃卡片背景（白）
  static Color get lightSurface => Colors.white.withValues(alpha: 0.70);

  /// 亮色模式 - 毛玻璃导航栏背景（更透）
  static Color get lightNavBar => Colors.white.withValues(alpha: 0.60);

  /// 亮色模式 - 毛玻璃面板背景（稍深）
  static Color get lightPanel =>
      const Color(0xFFF5F5F7).withValues(alpha: 0.80);

  /// 亮色模式 - 毛玻璃对话框背景
  static Color get lightDialog =>
      const Color(0xFFF9F9FA).withValues(alpha: 0.85);

  // ==================== 背景色（暗色模式） ====================

  /// 暗色模式 - 毛玻璃卡片背景
  static Color get darkSurface =>
      const Color(0xFF1C1C1E).withValues(alpha: 0.75);

  /// 暗色模式 - 毛玻璃导航栏背景
  static Color get darkNavBar =>
      const Color(0xFF1C1C1E).withValues(alpha: 0.65);

  /// 暗色模式 - 毛玻璃面板背景
  static Color get darkPanel => const Color(0xFF2C2C2E).withValues(alpha: 0.80);

  /// 暗色模式 - 毛玻璃对话框背景
  static Color get darkDialog =>
      const Color(0xFF2C2C2E).withValues(alpha: 0.85);

  // ==================== 边框色 ====================

  /// 亮色模式毛玻璃边框
  static Color get lightBorder => Colors.white.withValues(alpha: 0.50);

  /// 暗色模式毛玻璃边框
  static Color get darkBorder => Colors.white.withValues(alpha: 0.12);

  // ==================== 便捷方法 ====================

  /// 获取当前主题下的毛玻璃卡片背景色
  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  /// 获取当前主题下的毛玻璃导航栏背景色
  static Color navBar(BuildContext context) =>
      isDark(context) ? darkNavBar : lightNavBar;

  /// 获取当前主题下的毛玻璃面板背景色
  static Color panel(BuildContext context) =>
      isDark(context) ? darkPanel : lightPanel;

  /// 获取当前主题下的毛玻璃对话框背景色
  static Color dialogBg(BuildContext context) =>
      isDark(context) ? darkDialog : lightDialog;

  /// 获取当前主题下的毛玻璃边框色
  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

/// 毛玻璃容器 - 带模糊背景效果的 Card
///
/// 使用示例：
/// ```dart
/// GlassCard(
///   child: Text('内容'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? blurIntensity;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blurIntensity,
    this.boxShadow,
    this.onTap,
    this.foregroundColor,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Glass.isDark(context);
    final radius = borderRadius ?? 16.0;
    final blur = blurIntensity ?? Glass.cardBlur;
    final bgColor = foregroundColor ?? Glass.surface(context);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.08);

    final shadows =
        boxShadow ??
        [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -1,
          ),
        ];

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Glass.border(context), width: 0.5),
            boxShadow: shadows,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

/// 毛玻璃导航栏效果（用于 iOS 风格的大标题导航栏）
class GlassNavBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double? blurIntensity;
  final double elevation;

  const GlassNavBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.blurIntensity,
    this.elevation = 0.5,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final blur = blurIntensity ?? Glass.navBlur;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Glass.navBar(context),
            border: Border(
              bottom: BorderSide(color: Glass.border(context), width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: AppBar(
              title: title,
              leading: leading,
              actions: actions,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃底部导航栏
class GlassBottomNav extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double? blurIntensity;

  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.blurIntensity,
  });

  @override
  Widget build(BuildContext context) {
    final blur = blurIntensity ?? Glass.navBlur;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Glass.navBar(context),
            border: Border(
              top: BorderSide(color: Glass.border(context), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              items: items,
              currentIndex: currentIndex,
              onTap: onTap,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃底部面板包装器
///
/// 用于 iOS 风格的底部弹出面板
class GlassSheet extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final double? blurIntensity;

  const GlassSheet({
    super.key,
    required this.child,
    this.borderRadius,
    this.blurIntensity,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 16.0;
    final blur = blurIntensity ?? Glass.dialogBlur;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Glass.dialogBg(context),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 毛玻璃对话框包装器
class GlassDialog extends StatelessWidget {
  final Widget child;
  final double? borderRadius;

  const GlassDialog({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 20.0;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: Glass.dialogBlur,
              sigmaY: Glass.dialogBlur,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Glass.dialogBg(context),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Glass.border(context), width: 0.5),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
