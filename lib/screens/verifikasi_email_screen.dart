// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async'; // Untuk TimeoutException
import 'package:flutter/foundation.dart'; // Untuk kDebugMode
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/* ----------------------------- MODEL USER ----------------------------- */
class AppUser {
  final String id;
  final String? displayName;
  final String? photoUrl;
  final String? email; // Menambahkan email ke AppUser

  AppUser({required this.id, this.displayName, this.photoUrl, this.email});

  factory AppUser.fromJwt(Map<String, dynamic> jwt) => AppUser(
    id: jwt['id'],
    displayName: jwt['name'] ?? jwt['displayName'], // Perhatikan 'name' atau 'displayName' dari JWT
    photoUrl: jwt['photo'] ?? jwt['photoUrl'],     // Perhatikan 'photo' atau 'photoUrl' dari JWT
    email: jwt['email'], // Ambil email dari JWT
  );
}

/* ---------------------------- AUTH SERVICE ---------------------------- */
class AuthService {
  // Ganti dengan URL backend Anda yang sebenarnya.
  // Jika lokal, mungkin http://10.0.2.2:PORT_ANDA untuk emulator Android
  // atau http://localhost:PORT_ANDA untuk iOS simulator/web/desktop.
  // Untuk deployment, gunakan HTTPS.
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

  Future<String?> get token async => await _jwt; // Getter publik untuk token

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

      _logResponse(response, 'Google Sign-In');

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        if (token != null && token is String) {
          await _saveJwt(token); // Simpan JWT yang diterima dari backend
          return true;
        }
      }
      throw _parseErrorResponse(response, 'Autentikasi Google gagal');
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

      _logResponse(response, 'Login Email/Password');

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        if (token != null && token is String) {
          await _saveJwt(token); // Simpan JWT yang diterima dari backend
          return true;
        }
      }

      throw _parseErrorResponse(response, 'Login gagal');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Login gagal: ${e.toString()}');
    }
  }

  Future<bool> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      if (displayName.isEmpty) {
        throw Exception('Nama tampilan harus diisi');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'displayName': displayName}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Register Email/Password');

      if (response.statusCode == 201) {
        return true;
      }

      throw _parseErrorResponse(response, 'Registrasi gagal');
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
    try {
      final payload = JwtDecoder.decode(jwt);
      return AppUser.fromJwt(payload);
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
      await _clearJwt();
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (await _google.isSignedIn()) {
        await _google.signOut();
      }
      await _clearJwt();
    } catch (e) {
      throw Exception('Logout gagal: ${e.toString()}');
    }
  }

  Future<void> logout() async => await signOut();

  /* -------------------- EMAIL VERIFICATION -------------------- */
  // >>> START OF MODIFIED SECTION IN AUTH_SERVICE.DART <<<
  // Fungsi ini sekarang menerima 'userEmail' sebagai argumen
  Future<void> sendVerificationEmail(String userEmail) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': userEmail}), // Menggunakan userEmail yang diterima
    ).timeout(_timeoutDuration);

    _logResponse(response, 'Send Verification Email (Resend)');

    if (response.statusCode != 200) {
      throw _parseErrorResponse(response, 'Gagal mengirim email verifikasi');
    }
  }
  // >>> END OF MODIFIED SECTION IN AUTH_SERVICE.DART <<<

  Future<bool> isEmailVerified() async {
    final token = await _jwt;

    if (token == null) {
      debugPrint('No JWT token found for email verification check.');
      return false; // Mengembalikan false jika tidak ada token (belum login)
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/verified'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(_timeoutDuration);

    _logResponse(response, 'Check Email Verified Status');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['verified'] == true;
    } else if (response.statusCode == 401) {
      debugPrint('Token invalid or expired during email verification check. Clearing token.');
      await _clearJwt();
      throw Exception('Sesi Anda telah berakhir atau token tidak valid. Silakan login ulang.');
    } else {
      throw _parseErrorResponse(response, 'Gagal memeriksa status verifikasi');
    }
  }

  /* -------------------- HELPER METHODS -------------------- */
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _logResponse(http.Response response, String endpointName) {
    if (kDebugMode) {
      debugPrint('[$endpointName] Status: ${response.statusCode}');
      debugPrint('[$endpointName] Headers: ${response.headers}');
      debugPrint('[$endpointName] Body: ${response.body}');
    }
  }

  Exception _parseErrorResponse(http.Response response, String defaultMessage) {
    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? defaultMessage;
      return Exception(errorMessage);
    } catch (e) {
      return Exception('$defaultMessage: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
  }

  Future<void> _clearJwt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
  }
}