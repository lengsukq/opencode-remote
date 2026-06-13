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
  static const danger = Color(0xFFFF3B30);
  static const warning = Color(0xFFFF9500);

  static const shadow = Color(0x1A000000);
  static const shadowStrong = Color(0x26000000);
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

  static const shadow = Color(0x33000000);
  static const shadowStrong = Color(0x4C000000);
}
