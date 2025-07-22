// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Add Flutter material import
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
/// AuthService ini HANYA menggunakan Firebase untuk semua otentikasi.
/// Semua koneksi ke backend lama (icbs.my.id) telah dihapus.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Perbaikan: Hapus scope Drive yang tidak perlu
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream untuk memantau perubahan status otentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Mendaftarkan pengguna baru dengan email dan password menggunakan Firebase.
  /// Setelah berhasil, akan mengirimkan email verifikasi.
  Future<User?> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      // Buat pengguna langsung di Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Update nama tampilan & kirim email verifikasi
        await user.updateDisplayName(displayName);
        // Pastikan untuk mengaktifkan Email Verification di Firebase Console
        await user.sendEmailVerification();
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Menangani error spesifik dari Firebase seperti 'email-already-in-use'
      if (e.code == 'email-already-in-use') {
        throw Exception('Email ini sudah terdaftar. Silakan login atau gunakan email lain.');
      }
      // Memberikan pesan yang lebih mudah dimengerti untuk error umum lainnya
      else if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah. Harap gunakan password yang lebih kuat.');
      }
      throw Exception('Gagal mendaftar: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui saat registrasi.');
    }
  }

  /// Login dengan Google.
  /// Mengembalikan Map yang berisi UserCredential dan status apakah pengguna baru.
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

      // Tambahkan data pengguna ke Firestore jika pengguna baru
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
    return _auth.currentUser != null;
  }

  void handleTokenExpiration(BuildContext context) {
    // Contoh: langsung arahkan ke login
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<bool> refreshToken() async {
    // Firebase tidak support refresh token manual, jadi return true saja
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
}
