import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared input decoration helpers for consistent text field styling.
///
/// Usage:
/// ```dart
/// TextField(
///   decoration: AppInputDecoration.standard(hintText: '输入...'),
/// )
///
/// TextField(
///   decoration: AppInputDecoration.search(hintText: '搜索...'),
/// )
/// ```
class AppInputDecoration {
  AppInputDecoration._();

  /// Standard input decoration with filled background and themed borders.
  static InputDecoration standard({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textTertiary),
      labelText: labelText,
      labelStyle: TextStyle(color: AppColors.textSecondary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: AppColors.background,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.borderFocused),
      ),
      contentPadding: AppColors.kPaddingInput,
    );
  }

  /// Search-style input decoration with rounded, borderless appearance.
  static InputDecoration search({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textTertiary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: AppColors.kPaddingInput,
    );
  }
}
