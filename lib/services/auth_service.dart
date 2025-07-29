// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory AppUser.fromFirebase(User user) => AppUser(
        id: user.uid,
        name: user.displayName ?? 'Pengguna',
        photoUrl: user.photoURL,
        email: user.email ?? '',
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
  /// Login sebagai tamu (anonymous)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Gagal masuk sebagai tamu: e.toString()}');
    }
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream untuk memantau perubahan status otentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Mendaftarkan pengguna baru dengan email dan password menggunakan Firebase.
  Future<User?> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.sendEmailVerification();
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email ini sudah terdaftar. Silakan login atau gunakan email lain.');
      } else if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah. Harap gunakan password yang lebih kuat.');
      }
      throw Exception('Gagal mendaftar: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui saat registrasi.');
    }
  }

  /// Login dengan Google.
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login dengan Google dibatalkan.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await saveGoogleUserToFirestore(user);
      }

      return {
        'userCredential': userCredential,
        'isNewUser': isNewUser,
      };

    } catch (e) {
      throw Exception('Gagal login dengan Google: ${e.toString()}');
    }
  }

  /// Login dengan email dan password biasa.
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
       if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
         throw Exception('Email atau password yang Anda masukkan salah.');
       }
      throw Exception('Gagal login: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui saat login.');
    }
  }

  /// Keluar dari sesi saat ini.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Cek apakah pengguna sudah login
  Future<bool> isLoggedIn() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Jika anonymous, dianggap belum login
    if (user.isAnonymous) return false;
    return true;
  }

  void handleTokenExpiration(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<bool> refreshToken() async {
    return true;
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<AppUser?> getCurrentAppUser() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    return AppUser.fromFirebase(user);
  }

  Future<void> saveGoogleUserToFirestore(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? user.email,
      'photoURL': user.photoURL,
      'email': user.email,
    }, SetOptions(merge: true));
  }

  /// Perbaikan method saveArticle dengan proper token handling
  Future<bool> saveArticle(String url, bool save) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: User not logged in');
        return false;
      }

      // Dapatkan Firebase ID Token yang fresh
      final token = await user.getIdToken(true); // force refresh
      print('DEBUG: Got Firebase ID token');

      // PENTING: Ganti dengan URL API backend yang sebenarnya
      const String apiUrl = 'https://your-actual-backend-url.com/api/saved';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': user.uid,
          'url': url,
          'save': save,
        }),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('ERROR: API returned ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR: Exception in saveArticle: $e');
      return false;
    }
  }

  Future<void> removeBookmark(String userId, String articleUrl) async {
    final articleId = _getArticleId(articleUrl);
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('savedArticles')
      .doc(articleId)
      .delete();
  }

  String _getArticleId(String url) {
    // Implementasi untuk mendapatkan articleId dari URL
    return url.split('/').last;
  }
}