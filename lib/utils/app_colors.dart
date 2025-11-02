import 'package:flutter/material.dart';

/// Centralized color palette for the application
/// All colors are organized by theme and purpose
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============ PRIMARY COLORS ============
  static const Color primaryYellow = Color(0xFFFFEB3B); // Vibrant yellow - main accent
  static const Color primaryTeal = Color(0xFF4CAF50); // Teal/Green accent
  static const Color primaryRed = Color(0xFFD32F2F); // Strong red for alerts
  static const Color primaryBlue = Color(0xFF2196F3); // Blue for information
  static const Color primaryCoral = Color(0xFFE57373); // Coral/Salmon for warmth

  // ============ LIGHT THEME COLORS ============
  static const Color lightBackground = Color(0xFFFFF8E1); // Cream background
  static const Color lightSurface = Color(0xFFFFF8E1); // Cream surface
  static const Color lightText = Color(0xFF2E2E2E); // Dark text
  static const Color lightSecondaryText = Color(0xFF9E9E9E); // Gray text
  static const Color lightBorder = Color(0xFFFFEB3B); // Yellow border

  // ============ DARK THEME COLORS ============
  static const Color darkBackground = Color(0xFF2E2E2E); // Dark background
  static const Color darkSurface = Color(0xFF2E2E2E); // Dark surface
  static const Color darkText = Color(0xFFFFEB3B); // Yellow text
  static const Color darkSecondaryText = Color(0xFF9E9E9E); // Gray text
  static const Color darkBorder = Color(0xFFFFEB3B); // Yellow border

  // ============ SEMANTIC COLORS ============
  static const Color success = primaryTeal; // Success/positive feedback
  static const Color warning = Color(0xFFFFC107); // Warning color
  static const Color error = primaryRed; // Error color
  static const Color info = primaryBlue; // Information color

  // ============ UTILITY COLORS ============
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // ============ GRADIENT COLORS ============
  // Trending gradient (Blue)
  static const List<Color> trendingGradient = [
    Color(0xFF1976D2),
    Color(0xFF2196F3),
  ];

  // Highlight gradient (Green/Teal)
  static const List<Color> highlightGradient = [
    Color(0xFF388E3C),
    Color(0xFF4CAF50),
  ];

  // ============ HELPER METHODS ============
  /// Get colors based on theme brightness
  static Color getTextColor(bool isDark) =>
      isDark ? darkText : lightText;

  static Color getSecondaryTextColor(bool isDark) =>
      isDark ? darkSecondaryText : lightSecondaryText;

  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color getSurfaceColor(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  static Color getBorderColor(bool isDark) =>
      isDark ? darkBorder : lightBorder;

  /// Get opacity variants
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  static Color yellowWithOpacity(double opacity) =>
      primaryYellow.withValues(alpha: opacity);

  static Color grayWithOpacity(double opacity) =>
      lightSecondaryText.withValues(alpha: opacity);
}
