// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/* ----------------------------- MODEL USER ----------------------------- */
class AppUser {
  final String id;
  final String? displayName;
  final String? photoUrl;
<<<<<<< HEAD
  final String? email; // Menambahkan email
  final bool? isEmailVerified; // Menambahkan status verifikasi email
  final DateTime? createdAt; // Menambahkan waktu pembuatan akun
  final DateTime? lastLogin; // Menambahkan waktu login terakhir
=======
  final String? email;
  final bool? isEmailVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

  AppUser({
    required this.id,
    this.displayName,
    this.photoUrl,
    this.email,
    this.isEmailVerified,
    this.createdAt,
    this.lastLogin,
  });

<<<<<<< HEAD
  factory AppUser.fromJwt(Map<String, dynamic> jwt) {
    debugPrint('[AppUser.fromJwt] Decoding JWT payload: $jwt'); // Log payload
    return AppUser(
      id: jwt['id'] ?? jwt['userId'] ?? 'unknown_id', // Sesuaikan key 'userId' atau 'id' sesuai backend Anda
      displayName: jwt['displayName'] ?? jwt['name'], // Backend bisa kirim 'displayName' atau 'name' dari Google
      photoUrl: jwt['photoUrl'] ?? jwt['picture'], // Backend bisa kirim 'photoUrl' atau 'picture' dari Google
      email: jwt['email'],
      isEmailVerified: jwt['isEmailVerified'] ?? jwt['verified'] ?? false, // Backend bisa kirim 'isEmailVerified' atau 'verified'
      createdAt: jwt['createdAt'] != null ? DateTime.parse(jwt['createdAt']) : null,
      lastLogin: jwt['lastLogin'] != null ? DateTime.parse(jwt['lastLogin']) : null,
    );
  }
=======
  factory AppUser.fromJwt(Map<String, dynamic> jwt) => AppUser(
    id: jwt['id'],
    displayName: jwt['name'] ?? jwt['displayName'],
    photoUrl: jwt['photo'] ?? jwt['photoUrl'],
    email: jwt['email'],
    isEmailVerified: jwt['emailVerified'] ?? jwt['verified'],
    createdAt: jwt['createdAt'] != null ? DateTime.parse(jwt['createdAt']) : null,
    lastLogin: jwt['lastLogin'] != null ? DateTime.parse(jwt['lastLogin']) : null,
  );
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'email': email,
    'isEmailVerified': isEmailVerified,
    'createdAt': createdAt?.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
  };
}

/* ---------------------------- AUTH SERVICE ---------------------------- */
class AuthService {
  // PENTING: SESUAIKAN BASE URL INI DENGAN LINGKUNGAN ANDA!
  // Jika Anda menjalankan di emulator Android (backend di PC):
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // Jika Anda menjalankan di Flutter Web/Desktop atau emulator iOS (backend di PC):
  static const String baseUrl = 'http://localhost:5000/api'; // <--- PASTIKAN INI SESUAI

  // Jika Anda sudah mendeploy backend ke server produksi dengan domain dan HTTPS:
  // static const String baseUrl = 'https://icbs.my.id/api';
  
  static const String _jwtKey = 'jwt';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const Duration _timeoutDuration = Duration(seconds: 15);

  final GoogleSignIn _google = GoogleSignIn();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /* -------------------- INITIALIZATION -------------------- */
  Future<void> init() async {
    await SharedPreferences.getInstance();
    debugPrint('AuthService: SharedPreferences initialized.');
  }

  /* -------------------- TOKEN MANAGEMENT -------------------- */
  Future<void> _saveJwt(String jwt) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_jwtKey, jwt);
    final savedToken = prefs.getString(_jwtKey);
    debugPrint('AuthService: _saveJwt - Set String result: $success');
    debugPrint('AuthService: _saveJwt - Saved token verification: ${savedToken != null ? savedToken.substring(0, 10) + '...' : 'null'}');
  }

<<<<<<< HEAD
  Future<void> _saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_refreshTokenKey, refreshToken);
    final savedRefreshToken = prefs.getString(_refreshTokenKey);
    debugPrint('AuthService: _saveRefreshToken - Set String result: $success');
    debugPrint('AuthService: _saveRefreshToken - Saved refresh token verification: ${savedRefreshToken != null ? savedRefreshToken.substring(0, 10) + '...' : 'null'}');
  }

  Future<void> _saveUserData(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_userKey, jsonEncode(user.toJson()));
    debugPrint('AuthService: _saveUserData - Set String result: $success');
    debugPrint('AuthService: User data saved locally: ${user.email}.');
  }

  Future<String?> get _jwt async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_jwtKey);
    debugPrint('AuthService: _jwt getter - Retrieved from prefs: ${token != null ? token.substring(0, 10) + '...' : 'null'}');
    return token;
  }

  Future<String?> get _refreshToken async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshTokenKey);
    debugPrint('AuthService: _refreshToken getter - Retrieved from prefs: ${token != null ? token.substring(0, 10) + '...' : 'null'}');
    return token;
  }
=======
  Future<void> _saveRefreshToken(String refreshToken) async =>
      (await SharedPreferences.getInstance()).setString(_refreshTokenKey, refreshToken);

  Future<void> _saveUserData(AppUser user) async =>
      (await SharedPreferences.getInstance()).setString(_userKey, jsonEncode(user.toJson()));

  Future<String?> get _jwt async =>
      (await SharedPreferences.getInstance()).getString(_jwtKey);
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

  Future<String?> get _refreshToken async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  Future<String?> get token async => await _jwt;

  /* -------------------- TOKEN REFRESH -------------------- */
  Future<bool> refreshToken() async {
<<<<<<< HEAD
    debugPrint('[refreshToken] Attempting to refresh token...');
    try {
      final refreshToken = await _refreshToken;
      if (refreshToken == null) {
          debugPrint('[refreshToken] No Refresh Token found. Cannot refresh.');
          return false;
      }
=======
    try {
      final refreshToken = await _refreshToken;
      if (refreshToken == null) return false;
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(_timeoutDuration);

<<<<<<< HEAD
      _logResponse(response, 'Token Refresh Response');
=======
      _logResponse(response, 'Token Refresh');
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveJwt(data['token']);
        if (data['refreshToken'] != null) {
          await _saveRefreshToken(data['refreshToken']);
        }
<<<<<<< HEAD
        if (data['user'] != null) { 
          final user = AppUser.fromJwt(data['user']);
          await _saveUserData(user);
        }
        debugPrint('[refreshToken] Token refreshed. New JWT: ${data['token'].substring(0,10)}...');
        return true;
      }
      debugPrint('[refreshToken] Refresh failed with status: ${response.statusCode}');
      await _clearAllData();
      return false;
    } on TimeoutException {
      debugPrint('[refreshToken] Token refresh failed: TimeoutException');
      return false;
    } catch (e) {
      debugPrint('[refreshToken] Token refresh failed: $e');
      await _clearAllData();
=======
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      return false;
    }
  }

  Future<bool> _ensureValidToken() async {
    final jwt = await _jwt;
<<<<<<< HEAD
    debugPrint('[_ensureValidToken] JWT current: ${jwt != null ? jwt.substring(0, 10) + '...' : 'null'}');
    if (jwt == null) {
        debugPrint('[_ensureValidToken] No JWT found.');
        return false;
    }

    if (JwtDecoder.isExpired(jwt)) {
        debugPrint('[_ensureValidToken] JWT expired. Attempting refresh...');
        final refreshed = await refreshToken();
        if (refreshed) {
            debugPrint('[_ensureValidToken] Token refreshed successfully.');
        } else {
            debugPrint('[_ensureValidToken] Token refresh failed. Session invalid.');
        }
        return refreshed;
    }
    debugPrint('[_ensureValidToken] JWT is valid.');
=======
    if (jwt == null) return false;

    if (JwtDecoder.isExpired(jwt)) {
      return await refreshToken();
    }
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
    return true;
  }

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
        final data = jsonDecode(response.body);
        await _saveJwt(data['token']);
        if (data['refreshToken'] != null) {
          await _saveRefreshToken(data['refreshToken']);
        }
<<<<<<< HEAD
=======

        // Save user data if available
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
        if (data['user'] != null) {
          final user = AppUser.fromJwt(data['user']);
          await _saveUserData(user);
        }
<<<<<<< HEAD
=======

>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
        return true;
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
        final data = jsonDecode(response.body);
        await _saveJwt(data['token']);
        if (data['refreshToken'] != null) {
          await _saveRefreshToken(data['refreshToken']);
        }
<<<<<<< HEAD
=======

        // Save user data if available
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
        if (data['user'] != null) {
          final user = AppUser.fromJwt(data['user']);
          await _saveUserData(user);
        }
<<<<<<< HEAD
        return true;
      }

      // 🔥 PERBAIKAN DI SINI: Tangani error dengan _parseErrorResponse
      throw _parseErrorResponse(response, 'Login gagal'); // Pastikan ini dilempar

=======

        return true;
      }

      throw _parseErrorResponse(response, 'Login gagal');
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      // 🔥 PERBAIKAN DI SINI: Pastikan pesan exception selalu string valid
      throw Exception('Login gagal: ${e.toString()}'); // e.toString() di sini tidak bisa null
    }
  }

<<<<<<< HEAD
  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String displayName,
      String email,
      String password) async {
    try {
      if (!_isValidEmail(email)) {
        return { 'success': false, 'message': 'Format email tidak valid' };
=======
  Future<Map<String, dynamic>> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Format email tidak valid',
        };
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      }
      if (password.isEmpty || password.length < 6) {
<<<<<<< HEAD
        return { 'success': false, 'message': 'Password harus minimal 6 karakter' };
      }
      if (displayName.isEmpty) {
        return { 'success': false, 'message': 'Nama tampilan wajib diisi' };
=======
        return {
          'success': false,
          'message': 'Password harus minimal 6 karakter',
        };
      }

      if (displayName.isEmpty) {
        return {
          'success': false,
          'message': 'Nama tampilan harus diisi',
        };
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
<<<<<<< HEAD
        body: jsonEncode({
          'displayName': displayName,
          'email': email,
          'password': password,
        }),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Register Email/Password');
=======
        body: jsonEncode({'email': email, 'password': password, 'displayName': displayName}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Register Email/Password');

      final data = jsonDecode(response.body);
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
<<<<<<< HEAD
        if (data['token'] != null) {
          await _saveJwt(data['token']);
        }
        if (data['refreshToken'] != null) {
          await _saveRefreshToken(data['refreshToken']);
        }
        if (data['user'] != null) {
          final user = AppUser.fromJwt(data['user']);
          await _saveUserData(user);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Registrasi berhasil',
          'emailSent': data['emailSent'] ?? true,
          'userId': data['userId'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registrasi gagal',
        };
      }
    } on TimeoutException {
      return { 'success': false, 'message': 'Waktu koneksi habis. Periksa koneksi internet Anda.' };
    } catch (e) {
      debugPrint('Registrasi gagal: $e');
      return { 'success': false, 'message': 'Registrasi gagal: ${e.toString()}' };
=======
        return {
          'success': true,
          'message': 'Registrasi berhasil',
          'emailSent': data['emailSent'] ?? true,
          'userId': data['userId'],
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': data['message'] ?? 'Email sudah terdaftar',
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message': data['message'] ?? 'Data tidak valid',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Server error',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Koneksi timeout. Silakan coba lagi.',
      };
    } catch (e) {
      debugPrint('Registration error: $e');

      if (e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message': 'Tidak ada koneksi internet.',
        };
      } else {
        return {
          'success': false,
          'message': 'Terjadi kesalahan. Silakan coba lagi.',
        };
      }
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
    }
  }

  /* -------------------- PASSWORD MANAGEMENT -------------------- */
  Future<bool> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Reset Password');

      if (response.statusCode == 200) {
        return true;
      }

      throw _parseErrorResponse(response, 'Gagal mengirim email reset password');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Reset password gagal: ${e.toString()}');
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      if (!(await _ensureValidToken())) {
        throw Exception('Sesi tidak valid. Silakan login ulang.');
      }

<<<<<<< HEAD
=======
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        throw Exception('Password tidak boleh kosong');
      }

      if (newPassword.length < 6) {
        throw Exception('Password baru harus minimal 6 karakter');
      }

>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      final token = await _jwt;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Change Password');

      if (response.statusCode == 200) {
        return true;
      }

      throw _parseErrorResponse(response, 'Gagal mengubah password');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Ubah password gagal: ${e.toString()}');
    }
  }

  /* -------------------- USER MANAGEMENT -------------------- */
  Future<bool> isLoggedIn() async {
    final jwt = await _jwt;
    if (jwt == null) return false;

    if (JwtDecoder.isExpired(jwt)) {
      return await refreshToken();
    }
    return true;
  }

  Future<AppUser?> getCurrentUser() async {
    final jwt = await _jwt;
<<<<<<< HEAD
    if (jwt == null) {
      debugPrint('[AuthService.getCurrentUser] No JWT found.');
      return null;
    }

    if (JwtDecoder.isExpired(jwt)) {
      debugPrint('[AuthService.getCurrentUser] JWT expired. Attempting refresh...');
      final refreshed = await refreshToken();
      if (!refreshed) {
        debugPrint('[AuthService.getCurrentUser] Refresh failed after expiry. Clearing data.');
        await _clearAllData();
        return null;
      }
    }

    try {
      final currentJwt = await _jwt;
      if (currentJwt == null) {
        debugPrint('[AuthService.getCurrentUser] JWT is null after potential refresh. Should not happen if refresh succeeded.');
        return null;
      }

      final payload = JwtDecoder.decode(currentJwt);
      debugPrint('[AuthService.getCurrentUser] Decoded JWT payload: $payload');
      return AppUser.fromJwt(payload);
    } catch (e) {
      debugPrint('[AuthService.getCurrentUser] Error decoding JWT or getting current user: $e');
=======
    if (jwt == null) return null;

    if (JwtDecoder.isExpired(jwt)) {
      final refreshed = await refreshToken();
      if (!refreshed) return null;
    }

    try {
      final newJwt = await _jwt;
      if (newJwt == null) return null;

      final payload = JwtDecoder.decode(newJwt);
      return AppUser.fromJwt(payload);
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      await _clearAllData();
      return null;
    }
  }

  Future<bool> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      if (!(await _ensureValidToken())) {
        throw Exception('Sesi tidak valid. Silakan login ulang.');
      }

      final token = await _jwt;
      final Map<String, dynamic> updateData = {};

      if (displayName != null && displayName.isNotEmpty) {
        updateData['displayName'] = displayName;
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        updateData['photoUrl'] = photoUrl;
      }

      if (updateData.isEmpty) {
<<<<<<< HEAD
        return true;
=======
        throw Exception('Tidak ada data yang diubah');
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Update Profile');

      if (response.statusCode == 200) {
<<<<<<< HEAD
=======
        // Update local user data if available
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          final user = AppUser.fromJwt(data['user']);
          await _saveUserData(user);
        }
<<<<<<< HEAD
        if (data['token'] != null) {
          await _saveJwt(data['token']);
        }
=======
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
        return true;
      }

      throw _parseErrorResponse(response, 'Gagal mengubah profil');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Update profil gagal: ${e.toString()}');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      if (!(await _ensureValidToken())) {
        throw Exception('Sesi tidak valid. Silakan login ulang.');
      }

      final token = await _jwt;
      final response = await http.delete(
<<<<<<< HEAD
        Uri.parse('$baseUrl/account'),
=======
        Uri.parse('$baseUrl/auth/account'),
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Delete Account');

      if (response.statusCode == 200) {
        await signOut();
        return true;
      }

      throw _parseErrorResponse(response, 'Gagal menghapus akun');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Hapus akun gagal: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
<<<<<<< HEAD
=======
      // Optional: Notify server about logout
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      try {
        if (await _ensureValidToken()) {
          final token = await _jwt;
          await http.post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
<<<<<<< HEAD
          ).timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('Notifikasi logout server gagal: $e');
      }

      if (await _google.isSignedIn()) {
        await _google.signOut();
      }
=======
          ).timeout(Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('Server logout notification failed: $e');
      }

      // Sign out from Google
      if (await _google.isSignedIn()) {
        await _google.signOut();
      }

      // Clear all local data
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      await _clearAllData();
    } catch (e) {
      throw Exception('Logout gagal: ${e.toString()}');
    }
  }

  Future<void> logout() async => await signOut();

  /* -------------------- EMAIL VERIFICATION -------------------- */
<<<<<<< HEAD
  // Perbaikan tanda tangan fungsi ini untuk mengembalikan Map<String, dynamic>
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return { 'success': false, 'message': 'Format email tidak valid' };
      }

=======
  Future<void> sendVerificationEmail(String userEmail) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': userEmail}),
    ).timeout(_timeoutDuration);

    _logResponse(response, 'Send Verification Email (Resend)');

    if (response.statusCode != 200) {
      throw _parseErrorResponse(response, 'Gagal mengirim email verifikasi');
    }
  }

  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Resend Verification Email');

<<<<<<< HEAD
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend mengembalikan success true/false di body
        return { 'success': data['success'] == true, 'message': data['message'] ?? 'Email verifikasi berhasil dikirim ulang' };
      } else {
        throw _parseErrorResponse(response, 'Gagal mengirim email verifikasi');
      }
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      debugPrint('Error resending email verification: $e');
      throw Exception('Terjadi kesalahan saat mengirim email verifikasi: ${e.toString()}');
    }
  }


  Future<bool> verifyEmail(String verificationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': verificationCode}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Verify Email');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) { // Tambahkan cek success dari backend
          throw _parseErrorResponse(response, 'Kode verifikasi tidak valid atau sudah kadaluarsa');
        }
        
        // 🔥🔥 PENTING: Simpan token setelah verifikasi berhasil 🔥🔥
        if (data['token'] != null) {
          await _saveJwt(data['token']);
        }
        if (data['refreshToken'] != null) {
          await _saveRefreshToken(data['refreshToken']);
        }
        if (data['user'] != null) {
          final user = AppUser.fromJwt(data['user']);
          await _saveUserData(user);
        }
        // 🔥🔥 AKHIR PERBAIKAN 🔥🔥
        
        return true;
      }

      throw _parseErrorResponse(response, 'Kode verifikasi tidak valid atau sudah kadaluarsa');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      debugPrint('Verifikasi email gagal: $e');
      throw Exception('Verifikasi email gagal: ${e.toString()}');
    }
  }

  Future<bool> isEmailVerifiedStatus() async {
    final token = await _jwt;

    if (token == null) {
      debugPrint('Tidak ada JWT token untuk cek status verifikasi email.');
      return false;
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
      debugPrint('Token tidak valid atau kadaluarsa saat cek status verifikasi email. Bersihkan token.');
      await _clearAllData();
      throw Exception('Sesi Anda telah berakhir atau token tidak valid. Silakan login ulang.');
    } else {
      throw _parseErrorResponse(response, 'Gagal memeriksa status verifikasi');
    }
  }

  /* -------------------- ACCOUNT VALIDATION -------------------- */
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Check Email Exists');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Check email exists error: $e');
      return false;
    }
  }

  Future<bool> checkDisplayNameExists(String displayName) async {
    try {
      if (displayName.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-displayname'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'displayName': displayName.trim()}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Check Display Name Exists');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Check display name exists error: $e');
      return false;
    }
  }


  /* -------------------- HELPER METHODS -------------------- */
  void _logResponse(http.Response response, [String? endpointName]) {
    if (kDebugMode) {
      final prefix = endpointName != null ? '[$endpointName] ' : '';
      debugPrint('${prefix}Status: ${response.statusCode}');
      debugPrint('${prefix}Headers: ${response.headers}');
      debugPrint('${prefix}Body: ${response.body}');
    }
  }

  // 🔥 PERBAIKAN DI SINI: Pastikan errorMessage selalu non-null string
  Exception _parseErrorResponse(http.Response response, [String? defaultMessage]) {
    try {
      final errorData = jsonDecode(response.body);
      // Gunakan null-aware operator '?' dan ?? '' untuk memastikan string
      final errorMessage = (errorData['message']?.toString() ?? defaultMessage ?? 'Terjadi kesalahan (${response.statusCode})');
      return Exception(errorMessage);
    } catch (e) {
      // Pastikan e.toString() di-fallback ke string kosong jika bermasalah
      return Exception(defaultMessage ?? 'Terjadi kesalahan: ${response.body.isNotEmpty ? response.body : response.statusCode} - ${e.toString()}');
=======
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Email verifikasi berhasil dikirim ulang',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengirim email',
        };
      }
    } catch (e) {
      debugPrint('Resend email error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengirim email',
      };
    }
  }

  Future<bool> verifyEmail(String verificationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': verificationCode}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Verify Email');

      if (response.statusCode == 200) {
        return true;
      }

      throw _parseErrorResponse(response, 'Kode verifikasi tidak valid');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Verifikasi email gagal: ${e.toString()}');
    }
  }

  Future<bool> isEmailVerified() async {
    final token = await _jwt;

    if (token == null) {
      debugPrint('No JWT token found for email verification check.');
      return false;
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
      await _clearAllData();
      throw Exception('Sesi Anda telah berakhir atau token tidak valid. Silakan login ulang.');
    } else {
      throw _parseErrorResponse(response, 'Gagal memeriksa status verifikasi');
    }
  }

  /* -------------------- ACCOUNT VALIDATION -------------------- */
  Future<bool> checkEmailExists(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Check Email Exists');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Check email exists error: $e');
      return false;
    }
  }

  Future<bool> checkDisplayNameExists(String displayName) async {
    try {
      if (displayName.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-displayname'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'displayName': displayName}),
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Check Display Name Exists');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Check display name exists error: $e');
      return false;
    }
  }

  /* -------------------- HELPER METHODS -------------------- */
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isStrongPassword(String password) {
    if (password.length < 8) return false;

    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    bool hasDigits = RegExp(r'\d').hasMatch(password);
    bool hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  String getPasswordStrength(String password) {
    if (password.length < 6) return 'Terlalu pendek';
    if (password.length < 8) return 'Lemah';

    int score = 0;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    switch (score) {
      case 0:
      case 1:
        return 'Lemah';
      case 2:
        return 'Sedang';
      case 3:
        return 'Kuat';
      case 4:
        return 'Sangat Kuat';
      default:
        return 'Lemah';
    }
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
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
    }
  }

  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }
}