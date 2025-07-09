import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class MockAuthService {
  static const String _mockJwtKey = 'mock_jwt';
  static const String _mockUserKey = 'mock_user';

  // Mock login for testing
  Future<bool> mockLogin(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple validation
    if (email.isNotEmpty && password.length >= 6) {
      // Create mock JWT token
      final mockToken = _createMockJWT(email);
      final mockUser = AppUser(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        photoUrl: null,
      );
      
      // Save mock data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockJwtKey, mockToken);
      await prefs.setString(_mockUserKey, jsonEncode(mockUser.toJson()));
      
      return true;
    }
    
    return false;
  }

  // Create mock JWT token
  String _createMockJWT(String email) {
    final header = base64Encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
    final payload = base64Encode(utf8.encode(jsonEncode({
      'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
      'email': email,
      'name': email.split('@').first,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
    })));
    final signature = base64Encode(utf8.encode('mock_signature'));
    
    return '$header.$payload.$signature';
  }

  // Check if mock user is logged in
  Future<bool> isMockLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mockJwtKey) != null;
  }

  // Get mock user
  Future<AppUser?> getMockUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_mockUserKey);
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      return AppUser(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        photoUrl: userData['photoUrl'],
      );
    }
    return null;
  }

  // Mock logout
  Future<void> mockLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mockJwtKey);
    await prefs.remove(_mockUserKey);
  }
}
