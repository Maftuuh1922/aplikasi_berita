import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  void toggleTheme(bool value) {
    _isDarkMode = value;
    _saveTheme();
    notifyListeners();
  }
  
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2F80ED), // Button blue
      secondary: Color(0xFF6FCF97), // Green accent
      surface: Color(0xFFF8F4EC), // Soft cream background
      background: Color(0xFFF8F4EC), // Soft cream background
      error: Color(0xFFEB5757), // Soft red
      onPrimary: Color(0xFFFFFFFF), // White text on primary
      onSecondary: Color(0xFFFFFFFF), // White text on secondary
      onSurface: Color(0xFF4F4F4F), // Gray text on surface
      onBackground: Color(0xFF4F4F4F), // Gray text on background
      onError: Color(0xFFFFFFFF), // White text on error
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F4EC), // Soft cream background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8F4EC), // Soft cream background
      foregroundColor: Color(0xFF4F4F4F), // Gray text
      elevation: 0,
    ),
    useMaterial3: true,
  );
  
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2F80ED), // Button blue
      secondary: Color(0xFF6FCF97), // Green accent
      surface: Color(0xFF1A1A1A), // Dark surface
      background: Color(0xFF1A1A1A), // Dark background
      error: Color(0xFFEB5757), // Soft red
      onPrimary: Color(0xFFFFFFFF), // White text on primary
      onSecondary: Color(0xFFFFFFFF), // White text on secondary
      onSurface: Color(0xFFE5E5E5), // Light text on surface
      onBackground: Color(0xFFE5E5E5), // Light text on background
      onError: Color(0xFFFFFFFF), // White text on error
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Dark background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A), // Dark surface
      foregroundColor: Color(0xFFE5E5E5), // Light text
      elevation: 0,
    ),
    useMaterial3: true,
  );
  
  // Load theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme: $e');
    }
  }
  
  // Save theme preference to SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }
}