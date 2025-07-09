// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Add Flutter material import
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/* ----------------------------- MODEL USER ----------------------------- */
class AppUser {
  final String id;
  final String name;
  final String? photoUrl;
  final String email;

  AppUser({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.email,
  });

  factory AppUser.fromJwt(Map<String, dynamic> jwt) => AppUser(
        id: jwt['id'] ?? jwt['userId'] ?? '',
        name: jwt['displayName'] ?? jwt['name'] ?? 'Pengguna',
        photoUrl: jwt['photoUrl'] ?? jwt['picture'],
        email: jwt['email'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoUrl': photoUrl,
        'email': email,
      };
}

/* ---------------------------- AUTH SERVICE ---------------------------- */
class AuthService {
  static const String baseUrl = 'https://icbs.my.id/api';
  static const String _jwtKey = 'jwt';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const Duration _timeoutDuration = Duration(seconds: 30);

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

  Future<void> _saveRefreshToken(String refreshToken) async =>
      (await SharedPreferences.getInstance())
          .setString(_refreshTokenKey, refreshToken);

  Future<void> _saveUserData(AppUser user) async =>
      (await SharedPreferences.getInstance())
          .setString(_userKey, jsonEncode(user.toJson()));

  Future<String?> get _jwt async =>
      (await SharedPreferences.getInstance()).getString(_jwtKey);

  Future<String?> get _refreshToken async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  Future<String?> get token async => await _jwt;

  /* -------------------- TOKEN REFRESH -------------------- */
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        print('DEBUG: No refresh token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'];
        
        if (newToken != null) {
          await prefs.setString('jwt', newToken);
          if (newRefreshToken != null) {
            await prefs.setString('refresh_token', newRefreshToken);
          }
          print('DEBUG: Token refreshed successfully');
          return true;
        }
      } else {
        print('DEBUG: Token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Token refresh error: $e');
    }
    
    return false;
  }

  Future<bool> _ensureValidToken() async {
    final jwt = await _jwt;
    if (jwt == null) return false;

    if (JwtDecoder.isExpired(jwt)) {
      return await refreshToken();
    }
    return true;
  }

  /* -------------------- AUTHENTICATION METHODS -------------------- */
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeoutDuration);

      _logResponse(response, 'Login Email/Password');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if response contains an error message
        if (data['message'] != null && data['message'].contains('matchPassword is not a function')) {
          throw Exception('Masalah server backend. Silakan coba lagi nanti atau hubungi administrator.');
        }
        
        // Check if we have a valid token
        if (data['token'] != null) {
          await _saveJwt(data['token']);
          if (data['refreshToken'] != null) {
            await _saveRefreshToken(data['refreshToken']);
          }

          // Save user data if available
          if (data['user'] != null) {
            final user = AppUser.fromJwt(data['user']);
            await _saveUserData(user);
          }

          return true;
        } else {
          throw Exception('Response tidak valid dari server');
        }
      }

      throw _parseErrorResponse(response, 'Login gagal');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Login gagal: ${e.toString()}');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final gUser = await _google.signIn();
      if (gUser == null) return false;

      final gAuth = await gUser.authentication;
      
      // Enhanced request body for Google auth
      final requestBody = {
        'idToken': gAuth.idToken,
      };
      
      // Add access token if available
      if (gAuth.accessToken != null) {
        requestBody['accessToken'] = gAuth.accessToken!;
      }
      
      print('DEBUG: Sending Google auth request with: ${requestBody.keys}');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_timeoutDuration);

      _logResponse(response, 'Google Sign-In');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if response contains an error about missing token
        if (data['message'] != null && data['message'].contains('Token Google tidak ditemukan')) {
          throw Exception('Token Google tidak valid. Silakan coba login ulang.');
        }
        
        // Check if we have a valid token
        if (data['token'] != null) {
          await _saveJwt(data['token']);
          if (data['refreshToken'] != null) {
            await _saveRefreshToken(data['refreshToken']);
          }

          // Save user data if available
          if (data['user'] != null) {
            final user = AppUser.fromJwt(data['user']);
            await _saveUserData(user);
          }

          return true;
        } else {
          throw Exception('Response tidak valid dari server');
        }
      }
      throw _parseErrorResponse(response, 'Autentikasi Google gagal');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Error Google Sign-In: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Format email tidak valid',
        };
      }

      if (password.isEmpty || password.length < 6) {
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
      }

      // Enhanced request body to include all required fields
      final requestBody = {
        'email': email,
        'password': password,
        'displayName': displayName,
        'username': displayName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), ''),
        'name': displayName, // Add name field as well
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_timeoutDuration);

      _logResponse(response, 'Register Email/Password');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registrasi berhasil',
          'emailSent': data['emailSent'] ?? true,
          'userId': data['userId'],
        };
      } else if (response.statusCode == 400) {
        String errorMessage = data['message'] ?? 'Email sudah terdaftar';
        
        // Handle specific backend validation errors
        if (errorMessage.contains('Username is required')) {
          errorMessage = 'Masalah validasi backend. Silakan coba lagi.';
        }
        
        return {
          'success': false,
          'message': errorMessage,
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
    }
  }

  /* -------------------- PASSWORD MANAGEMENT -------------------- */
  Future<bool> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(_timeoutDuration);

      _logResponse(response, 'Reset Password');

      if (response.statusCode == 200) {
        return true;
      }

      throw _parseErrorResponse(
          response, 'Gagal mengirim email reset password');
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Reset password gagal: ${e.toString()}');
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      if (!(await _ensureValidToken())) {
        throw Exception('Sesi tidak valid. Silakan login ulang.');
      }

      if (currentPassword.isEmpty || newPassword.isEmpty) {
        throw Exception('Password tidak boleh kosong');
      }

      if (newPassword.length < 6) {
        throw Exception('Password baru harus minimal 6 karakter');
      }

      final token = await _jwt;
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/change-password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(_timeoutDuration);

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
      await _clearAllData();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (!(await _ensureValidToken())) {
        throw Exception('Sesi tidak valid. Silakan login ulang.');
      }

      final token = await _jwt;
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeoutDuration);

      _logResponse(response, 'Get User Profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    String? displayName, 
    String? email,
    String? phone,
    String? bio,
    String? photoUrl
  }) async {
    try {
      if (!(await _ensureValidToken())) {
        throw Exception('Sesi tidak valid. Silakan login ulang.');
      }

      final token = await _jwt;
      final Map<String, dynamic> updateData = {};

      if (displayName != null && displayName.isNotEmpty) {
        updateData['displayName'] = displayName;
      }
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }
      if (bio != null && bio.isNotEmpty) {
        updateData['bio'] = bio;
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        updateData['photoUrl'] = photoUrl;
      }

      if (updateData.isEmpty) {
        throw Exception('Tidak ada data yang diubah');
      }

      final response = await http
          .patch(
            Uri.parse('$baseUrl/auth/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(updateData),
          )
          .timeout(_timeoutDuration);

      _logResponse(response, 'Update Profile');

      if (response.statusCode == 200) {
        // Update local user data if available
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          final user = AppUser.fromJwt(data['user']);
          await _saveUserData(user);
        }
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
        Uri.parse('$baseUrl/auth/account'),
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
      // Optional: Notify server about logout
      try {
        if (await _ensureValidToken()) {
          final token = await _jwt;
          await http.post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
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
      await _clearAllData();
    } catch (e) {
      throw Exception('Logout gagal: ${e.toString()}');
    }
  }

  Future<void> logout() async => await signOut();

  /* -------------------- EMAIL VERIFICATION -------------------- */
  Future<void> sendVerificationEmail(String userEmail) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/resend'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': userEmail}),
        )
        .timeout(_timeoutDuration);

    _logResponse(response, 'Send Verification Email (Resend)');

    if (response.statusCode != 200) {
      throw _parseErrorResponse(response, 'Gagal mengirim email verifikasi');
    }
  }

  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/resend'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(_timeoutDuration);

      _logResponse(response, 'Resend Verification Email');

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
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': verificationCode}),
          )
          .timeout(_timeoutDuration);

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

  /* -------------------- OTP VERIFICATION -------------------- */
  Future<bool> verifyEmailWithOTP(String email, String otpCode) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }
      if (otpCode.isEmpty || otpCode.length != 6) {
        throw Exception('Kode OTP harus 6 digit');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otpCode,
            }),
          )
          .timeout(_timeoutDuration);

      _logResponse(response, 'Verify OTP');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Jika server mengembalikan token setelah verifikasi berhasil
        if (data['token'] != null) {
          await _saveJwt(data['token']);
          if (data['refreshToken'] != null) {
            await _saveRefreshToken(data['refreshToken']);
          }

          // Save user data if available
          if (data['user'] != null) {
            final user = AppUser.fromJwt(data['user']);
            await _saveUserData(user);
          }
        }

        return true;
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Kode OTP tidak valid');
      } else if (response.statusCode == 410) {
        throw Exception('Kode OTP telah kedaluwarsa');
      } else {
        throw _parseErrorResponse(response, 'Verifikasi OTP gagal');
      }
    } on TimeoutException {
      throw Exception('Waktu koneksi habis. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Verifikasi OTP gagal: ${e.toString()}');
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
      debugPrint(
          'Token invalid or expired during email verification check. Clearing token.');
      await _clearAllData();
      throw Exception(
          'Sesi Anda telah berakhir atau token tidak valid. Silakan login ulang.');
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

      final response = await http.get(
        Uri.parse('$baseUrl/user/check-email?email=$email'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      _logResponse(response, 'Check Email Exists');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } on TimeoutException {
      debugPrint('Check email exists error: Timeout, server tidak merespon.');
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/check-displayname'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'displayName': displayName}),
          )
          .timeout(_timeoutDuration);

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
    bool hasSpecialCharacters =
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

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
      return Exception(
          '$defaultMessage: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
  }

  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // Add this debug method to check token validity
  Future<void> debugTokenStatus() async {
    try {
      final token = await _jwt;
      if (token == null) {
        print('DEBUG: No JWT token found');
        return;
      }
      
      if (JwtDecoder.isExpired(token)) {
        print('DEBUG: JWT token is expired');
        final refreshed = await refreshToken();
        print('DEBUG: Token refresh result: $refreshed');
      } else {
        print('DEBUG: JWT token is valid');
      }
      
      final payload = JwtDecoder.decode(token);
      print('DEBUG: Token payload: ${payload.toString()}');
    } catch (e) {
      print('DEBUG: Token check error: $e');
    }
  }

  Future<void> handleTokenExpiration(BuildContext? context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    
    if (context != null && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
