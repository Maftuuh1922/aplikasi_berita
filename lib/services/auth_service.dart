import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async'; // Untuk TimeoutException
import 'package:flutter/foundation.dart'; // Untuk kDebugMode

/* ----------------------------- MODEL USER ----------------------------- */
class AppUser {
  final String id;
  final String? displayName;
  final String? photoUrl;

  AppUser({required this.id, this.displayName, this.photoUrl});

  factory AppUser.fromJwt(Map<String, dynamic> jwt) => AppUser(
    id: jwt['id'],
    displayName: jwt['displayName'],
    photoUrl: jwt['photoUrl'],
  );
}

/* ---------------------------- AUTH SERVICE ---------------------------- */
class AuthService {
  static const String baseUrl = 'https://icbs.my.id/api';
  static const String _jwtKey = 'jwt';
  static const Duration _timeoutDuration = Duration(seconds: 15);

  final GoogleSignIn _google = GoogleSignIn();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /* -------------------- INITIALIZATION -------------------- */
  Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  /* -------------------- TOKEN MANAGEMENT -------------------- */
  Future<void> _saveJwt(String jwt) async =>
      (await SharedPreferences.getInstance()).setString(_jwtKey, jwt);

  Future<String?> get _jwt async =>
      (await SharedPreferences.getInstance()).getString(_jwtKey);

  Future<String?> get token async => await _jwt;

  /* -------------------- AUTHENTICATION METHODS -------------------- */
  Future<bool> signInWithGoogle() async {
    try {
      final gUser = await _google.signIn();
      if (gUser == null) return false;

      final gAuth = await gUser.authentication;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': gAuth.idToken}),
      ).timeout(_timeoutDuration);

      _logResponse(response);

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        if (token != null && token is String) {
          await _saveJwt(token);
          return true;
        }
      }
      throw Exception('Autentikasi Google gagal');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Error Google Sign-In: ${e.toString()}');
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeoutDuration);

      _logResponse(response);

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        if (token != null && token is String) {
          await _saveJwt(token);
          return true;
        }
      }

      throw _parseErrorResponse(response);
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Login gagal: ${e.toString()}');
    }
  }

  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeoutDuration);

      _logResponse(response);

      if (response.statusCode == 201) {
        return true;
      }

      throw _parseErrorResponse(response);
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Registrasi gagal: ${e.toString()}');
    }
  }

  /* -------------------- USER MANAGEMENT -------------------- */
  Future<bool> isLoggedIn() async {
    final jwt = await _jwt;
    return jwt != null && !JwtDecoder.isExpired(jwt);
  }

  Future<AppUser?> getCurrentUser() async {
    final jwt = await _jwt;
    if (jwt == null || JwtDecoder.isExpired(jwt)) return null;
    final payload = JwtDecoder.decode(jwt);
    return AppUser.fromJwt(payload);
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_jwtKey);
    } catch (e) {
      throw Exception('Logout gagal: ${e.toString()}');
    }
  }

  Future<void> logout() async => await signOut();

  /* -------------------- HELPER METHODS -------------------- */
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _logResponse(http.Response response) {
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Headers: ${response.headers}');
    debugPrint('Body: ${response.body}');
  }

  Exception _parseErrorResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ??
          'Terjadi kesalahan (${response.statusCode})';
      return Exception(errorMessage);
    } catch (e) {
      return Exception('Terjadi kesalahan: ${response.body}');
    }
  }
}