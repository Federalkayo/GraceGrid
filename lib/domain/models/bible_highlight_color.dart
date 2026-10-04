import 'package:flutter/material.dart';

/// Preset highlight colors for Bible verses.
class BibleHighlightColor {
  static const String yellow = 'yellow';
  static const String green = 'green';
  static const String blue = 'blue';
  static const String pink = 'pink';
  static const String orange = 'orange';

  static const List<String> allColors = [yellow, green, blue, pink, orange];

  /// Returns a semi-transparent background color for highlighted verse cards.
  static Color getColor(String? colorName, bool isDark) {
    if (colorName == null || colorName.isEmpty) return Colors.transparent;

    switch (colorName.toLowerCase()) {
      case yellow:
        return isDark
            ? const Color(0xFFFEF08A).withValues(alpha: 0.18)
            : const Color(0xFFFEF08A).withValues(alpha: 0.55);
      case green:
        return isDark
            ? const Color(0xFF86EFAC).withValues(alpha: 0.18)
            : const Color(0xFFBBF7D0).withValues(alpha: 0.55);
      case blue:
        return isDark
            ? const Color(0xFF93C5FD).withValues(alpha: 0.18)
            : const Color(0xFFBFDBFE).withValues(alpha: 0.55);
      case pink:
        return isDark
            ? const Color(0xFFF472B6).withValues(alpha: 0.18)
            : const Color(0xFFFBCFE8).withValues(alpha: 0.55);
      case orange:
        return isDark
            ? const Color(0xFFFDBA74).withValues(alpha: 0.18)
            : const Color(0xFFFED7AA).withValues(alpha: 0.55);
      default:
        return isDark
            ? const Color(0xFFFEF08A).withValues(alpha: 0.18)
            : const Color(0xFFFEF08A).withValues(alpha: 0.55);
    }
  }

  /// Returns the solid accent color used for left border lines and swatches.
  static Color getAccentColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) return Colors.transparent;

    switch (colorName.toLowerCase()) {
      case yellow:
        return const Color(0xFFEAB308);
      case green:
        return const Color(0xFF22C55E);
      case blue:
        return const Color(0xFF3B82F6);
      case pink:
        return const Color(0xFFEC4899);
      case orange:
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFEAB308);
    }
  }

  /// Returns a human-readable display label for the color.
  static String getLabel(String colorName) {
    switch (colorName.toLowerCase()) {
      case yellow:
        return 'Gold';
      case green:
        return 'Emerald';
      case blue:
        return 'Sky Blue';
      case pink:
        return 'Rose';
      case orange:
        return 'Amber';
      default:
        return colorName;
    }
  }
}
