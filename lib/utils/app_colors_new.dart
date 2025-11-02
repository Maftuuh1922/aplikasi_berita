import 'package:flutter/material.dart';

/// Centralized color palette for the News Application
/// Modern pastel colors with Material Design 3
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============ PRIMARY COLORS - PASTEL THEME ============
  static const Color backgroundCream = Color(0xFFF8F4EC); // Main background - soft cream
  static const Color cardYellow = Color(0xFFF8D47E); // Technology card
  static const Color cardGreen = Color(0xFF6FCF97); // Health card
  static const Color cardRed = Color(0xFFEB5757); // Politics card
  static const Color cardBlue = Color(0xFF56CCF2); // Sports card
  
  // ============ TEXT COLORS ============
  static const Color textGray = Color(0xFF4F4F4F); // Primary text color
  static const Color textLight = Color(0xFFBDBDBD); // Secondary text
  static const Color buttonBlue = Color(0xFF2F80ED); // Button primary color
  
  // ============ UTILITY COLORS ============
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ============ CATEGORY CARD COLORS ============
  // Mapped for different news categories
  static const Map<String, Color> categoryColors = {
    'teknologi': cardYellow,
    'kesehatan': cardGreen,
    'politik': cardRed,
    'olahraga': cardBlue,
    'bisnis': cardBlue,
    'nasional': cardRed,
    'internasional': cardBlue,
    'hiburan': cardYellow,
    'default': cardBlue,
  };

  // ============ SHADOW STYLE - SOFT & SUBTLE ============
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // ============ HELPER METHODS ============
  /// Get category color based on category name
  static Color getCategoryColor(String category) {
    return categoryColors[category.toLowerCase()] ?? categoryColors['default']!;
  }

  /// Get contrasting text color for card backgrounds
  static Color getContrastingTextColor(Color backgroundColor) {
    // Check if background is light or dark
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textGray : white;
  }

  /// Create a semi-transparent color
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
