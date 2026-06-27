import 'package:flutter/material.dart';

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
///
/// The decoration relies on the [IOSTheme] input decoration theme for
/// borders, colors, and typography. Only pass overrides when needed.
class AppInputDecoration {
  AppInputDecoration._();

  /// Standard input decoration using theme defaults for borders and fill.
  static InputDecoration standard({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
    );
  }

  /// Search-style input decoration using theme defaults with a borderless
  /// appearance for compact search fields.
  static InputDecoration search({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
    );
  }
}
