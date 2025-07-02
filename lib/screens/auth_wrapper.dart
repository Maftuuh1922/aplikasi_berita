import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart'; // Pastikan file ini ada

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika masih loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Jika ada error
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Something went wrong'),
            ),
          );
        }

        // Jika user sudah login
        if (snapshot.hasData) {
          return const HomeScreen(); // Pastikan HomeScreen sudah dibuat
        }

        // Jika user belum login
        return const LoginScreen();
      },
    );
  }
}