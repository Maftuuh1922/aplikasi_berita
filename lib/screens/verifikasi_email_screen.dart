import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'isi_profil_screen.dart';

class VerifikasiEmailScreen extends StatefulWidget {
  // Constructor sudah tidak memerlukan parameter 'user'
  const VerifikasiEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifikasiEmailScreen> createState() => _VerifikasiEmailScreenState();
}

class _VerifikasiEmailScreenState extends State<VerifikasiEmailScreen> {
  Timer? _timer;
  bool _canResendEmail = true;

  @override
  void initState() {
    super.initState();
    // Langsung mulai timer untuk mengecek status verifikasi
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Fungsi ini akan secara aktif memeriksa status verifikasi dari server
  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      _timer?.cancel();
      return;
    }

    // Perintah ini penting: memuat ulang status user dari server Firebase
    await user.reload();
    user = FirebaseAuth.instance.currentUser; // Ambil lagi data user yang sudah di-reload

    // Jika email sudah terverifikasi
    if (user?.emailVerified ?? false) {
      _timer?.cancel(); // Hentikan timer
      
      if (mounted) {
        // Arahkan ke halaman untuk melengkapi profil
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const IsiProfilScreen()),
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResendEmail) {
      _showSnack('Harap tunggu sebelum mengirim ulang email.', isSuccess: false);
      return;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _showSnack('Email verifikasi telah dikirim ulang.', isSuccess: true);
        
        setState(() => _canResendEmail = false);
        Future.delayed(const Duration(seconds: 60), () {
          if (mounted) {
            setState(() => _canResendEmail = true);
          }
        });
      }
    } catch (e) {
      _showSnack('Gagal mengirim ulang email: $e', isSuccess: false);
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'email Anda';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verifikasi Email Anda'),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      // PERBAIKAN: Menggunakan SingleChildScrollView untuk mencegah overflow
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20), // Padding atas
                const Icon(Icons.mark_email_read_outlined, size: 100, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Satu Langkah Lagi!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Kami telah mengirimkan link verifikasi ke email:\n$userEmail\n\nSilakan cek kotak masuk (atau folder spam) Anda dan klik link tersebut untuk melanjutkan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Menunggu verifikasi...'),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _sendVerificationEmail,
                  icon: const Icon(Icons.send),
                  label: const Text('Kirim Ulang Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canResendEmail ? Colors.blue : Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if(mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: const Text('Ganti Akun'),
                ),
                const SizedBox(height: 20), // Padding bawah
              ],
            ),
          ),
        ),
      ),
    );
  }
}
