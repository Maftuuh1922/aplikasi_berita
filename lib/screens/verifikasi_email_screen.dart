// lib/screens/verifikasi_email_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';

class VerifikasiEmailScreen extends StatefulWidget {
  final String userEmail;
  final bool showResendButton;

  const VerifikasiEmailScreen({
    Key? key,
    required this.userEmail,
    this.showResendButton = false,
  }) : super(key: key);

  @override
  State<VerifikasiEmailScreen> createState() => _VerifikasiEmailScreenState();
}

class _VerifikasiEmailScreenState extends State<VerifikasiEmailScreen> {
  bool _isResending = false;
  bool _canResend = true;
  bool _isLoading = false;
  int _resendCountdown = 0;
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.showResendButton) {
      _startResendCooldown();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() => _isResending = true);

    try {
      final result = await _authService.resendVerificationEmail(widget.userEmail);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnack('Email verifikasi telah dikirim ulang', isSuccess: true);
        _startResendCooldown();
      } else {
        _showSnack('Gagal kirim ulang: ${result['message']}', isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal kirim ulang: ${e.toString()}', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startResendCooldown() {
    _timer?.cancel();
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_resendCountdown > 0) {
          setState(() => _resendCountdown--);
        } else {
          timer.cancel();
          setState(() => _canResend = true);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtpCode() async {
    if (_otpController.text.trim().isEmpty) {
      _showSnack('Kode OTP tidak boleh kosong', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool verified = await _authService.verifyEmail(_otpController.text.trim());

      if (!mounted) return;

      if (verified) {
        _showSnack('Email berhasil diverifikasi!', isSuccess: true);
        Navigator.of(context).pushReplacementNamed('/isi-profil'); // Mengarah ke IsiProfilScreen
      } else {
        _showSnack('Kode verifikasi tidak valid atau sudah kadaluarsa.', isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal verifikasi email: ${e.toString()}', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green.shade400 : Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verifikasi Email'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardSpace),
          child: Column(
            // --- PERBAIKAN DI SINI ---
            mainAxisAlignment: MainAxisAlignment.center, // Tetap center untuk vertical alignment
            mainAxisSize: MainAxisSize.min, // <-- PENTING: Gunakan MainAxisSize.min
            // --- AKHIR PERBAIKAN ---
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 50,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Verifikasi Email Anda',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Kami telah mengirim email verifikasi ke:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  widget.userEmail,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Silakan cek email Anda dan masukkan kode verifikasi di bawah ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Masukkan Kode Verifikasi (OTP)',
                    hintText: 'Misal: 123456',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtpCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Verifikasi Kode',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (_isResending || !_canResend) ? null : _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isResending
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade600,
                          ),
                        )
                      : Text(
                          _canResend
                              ? 'Kirim Ulang Email'
                              : 'Kirim Ulang ($_resendCountdown)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _canResend ? Colors.blue.shade600 : Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Ini tetap mengarah ke Login, karena user sudah di verify atau bisa login dari sana
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}