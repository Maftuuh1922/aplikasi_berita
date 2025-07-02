import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'isi_profil_screen.dart';

class VerifikasiEmailScreen extends StatefulWidget {
  const VerifikasiEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifikasiEmailScreen> createState() => _VerifikasiEmailScreenState();
}

class _VerifikasiEmailScreenState extends State<VerifikasiEmailScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startEmailCheckTimer();
  }

  void _startEmailCheckTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user != null && user.emailVerified) {
        _timer.cancel();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const IsiProfilScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verifikasi Email")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Kami telah mengirim email verifikasi.\nSilakan cek dan klik link verifikasi."),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.currentUser?.reload();
                if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const IsiProfilScreen()),
                  );
                }
              },
              child: const Text("Saya sudah verifikasi"),
            ),
          ],
        ),
      ),
    );
  }
}
