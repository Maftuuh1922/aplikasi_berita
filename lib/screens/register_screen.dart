// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
<<<<<<< HEAD
import 'verifikasi_email_screen.dart' show VerifikasiEmailScreen;
=======
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

class RegisterScreen extends StatefulWidget {
  final String? userEmail; // Made optional

  const RegisterScreen({Key? key, this.userEmail}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

<<<<<<< HEAD
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController(); // Controller untuk Nama Tampilan
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
=======
  final _formKey               = GlobalKey<FormState>();
  final _emailCtrl             = TextEditingController();
  final _passwordCtrl          = TextEditingController();
  final _confirmPasswordCtrl   = TextEditingController();
  final _displayNameCtrl       = TextEditingController();
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided
    if (widget.userEmail != null) {
      _emailCtrl.text = widget.userEmail!;
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose(); // Dispose controller nama tampilan
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  /* ---------------- register via backend WITH EMAIL VERIFICATION ---------------- */
  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
<<<<<<< HEAD
      // Panggilan ke AuthService dengan urutan parameter yang benar: displayName, email, password
      final result = await _authService.registerWithEmailAndPassword(
        _displayNameCtrl.text.trim(), // Trim Nama Tampilan
        _emailCtrl.text.trim(),       // Trim Email
=======
      // Langkah 1: Cek apakah email sudah terdaftar
      final isEmailExists = await _authService.checkEmailExists(_emailCtrl.text.trim());
      if (isEmailExists) {
        _showSnack('Email sudah terdaftar. Silakan gunakan email lain atau login.');
        return;
      }

      // Langkah 2: Registrasi user DAN kirim email verifikasi
      final result = await _authService.registerWithEmailAndPassword(
        _emailCtrl.text.trim(),
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
        _passwordCtrl.text,
        _displayNameCtrl.text.trim(),
      );

      if (!mounted) return;

<<<<<<< HEAD
      // Check if registration was successful
      if (result['success'] == true) {
        debugPrint('[RegisterScreen] Registration success! Navigating to VerifikasiEmailScreen.');
        // setelah backend sukses create user & kirim email‑verif,
        // arahkan user ke layar cek‑email dengan email yang didaftarkan
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifikasiEmailScreen(
              userEmail: _emailCtrl.text.trim(),
              showResendButton: true,
            ),
          ),
        );
      } else {
        // Show error message from backend
        debugPrint('[RegisterScreen] Registration failed: ${result['message']}');
        _showSnack(result['message'] ?? 'Pendaftaran gagal. Silakan coba lagi.');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[RegisterScreen] Registration Exception: $e');
      _showSnack('Gagal daftar: $e');
=======
      // Langkah 3: Cek apakah registrasi DAN pengiriman email berhasil
      if (result['success'] == true) {
        // Jika ada informasi tambahan dari backend tentang status email
        if (result['emailSent'] == true) {
          // Email berhasil dikirim, arahkan ke halaman verifikasi
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                userEmail: _emailCtrl.text.trim(),
              ),
            ),
          );
        } else {
          // Registrasi berhasil tapi email gagal dikirim
          _showSnack('Registrasi berhasil, tetapi email verifikasi gagal dikirim. Silakan coba kirim ulang.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                userEmail: _emailCtrl.text.trim(),
                showResendButton: true,
              ),
            ),
          );
        }
      } else {
        // Registrasi gagal total
        final errorMessage = result['message'] ?? 'Pendaftaran gagal. Silakan coba lagi.';
        _showSnack(errorMessage);
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      // Handle different types of errors
      if (errorMessage.contains('email already exists')) {
        errorMessage = 'Email sudah terdaftar. Silakan gunakan email lain.';
      } else if (errorMessage.contains('network')) {
        errorMessage = 'Koneksi internet bermasalah. Silakan coba lagi.';
      } else if (errorMessage.contains('email service')) {
        errorMessage = 'Layanan email sedang bermasalah. Silakan coba lagi nanti.';
      }

      _showSnack('Gagal daftar: $errorMessage');
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
=======
    SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
    ),
  );
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildBackButton(context),
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildDisplayNameField(), // Menambahkan field Nama Tampilan
                    const SizedBox(height: 16),
                    _buildEmailField(), // Field Email
                    const SizedBox(height: 16),
<<<<<<< HEAD
                    _buildPasswordField(), // Field Password
                    const SizedBox(height: 16),
                    _buildConfirmField(), // Field Konfirmasi Password
=======
                    _buildConfirmField(),
                    const SizedBox(height: 16),
                    _buildDisplayNameField(),
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildLoginLink(context),
            ],
          ),
        ),
      ),
    );
  }

  /* ------- widgets kecil -------- */
  Widget _buildBackButton(BuildContext ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black54),
        ),
      );

  Widget _buildLogo() => Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/Bebas Neue.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.newspaper, size: 40, color: Colors.blue.shade600),
            ),
          ),
        ),
      );

  Widget _buildTitle() => Column(
        children: [
          const Text(
            "Buat Akun Baru",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Daftar dengan email dan password Anda",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      );

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      );

  // Widget untuk field Nama Tampilan
  Widget _buildDisplayNameField() => TextFormField(
        controller: _displayNameCtrl,
        keyboardType: TextInputType.text,
        decoration: _inputDec('Nama Tampilan', Icons.person_outline),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Nama tampilan wajib diisi';
          return null;
        },
      );

  // Widget untuk field Email (sudah diperbaiki dengan .trim())
  Widget _buildEmailField() => TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDec('Email', Icons.email_outlined),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email wajib diisi';
          final trimmedEmail = v.trim(); // Penting: Trim email sebelum validasi regex
          final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!regex.hasMatch(trimmedEmail)) return 'Format email tidak valid';
          return null;
        },
      );

  Widget _buildPasswordField() => TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        decoration: _inputDec('Password', Icons.lock_outline).copyWith(
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password wajib diisi';
          if (v.length < 6) return 'Password minimal 6 karakter';
          return null;
        },
      );

  Widget _buildConfirmField() => TextFormField(
        controller: _confirmPasswordCtrl,
        obscureText: _obscureConfirmPassword,
        decoration: _inputDec('Konfirmasi Password', Icons.lock_outline).copyWith(
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            child: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
          if (v != _passwordCtrl.text) return 'Password tidak cocok';
          return null;
        },
      );

  Widget _buildDisplayNameField() => TextFormField(
    controller: _displayNameCtrl,
    keyboardType: TextInputType.text,
    decoration: _inputDec('Nama Tampilan', Icons.person_outline),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Nama Tampilan wajib diisi';
      return null;
    },
  );

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleEmailRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text("Daftar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _buildLoginLink(BuildContext ctx) => Row(
<<<<<<< HEAD
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Sudah punya akun? ", style: TextStyle(color: Colors.grey.shade600)),
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Text("Masuk",
                style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
          ),
        ],
      );
=======
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("Sudah punya akun? ", style: TextStyle(color: Colors.grey.shade600)),
      GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Text("Masuk",
            style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

// Email Verification Screen dengan handling yang lebih baik
class EmailVerificationScreen extends StatefulWidget {
  final String userEmail;
  final bool showResendButton;

  const EmailVerificationScreen({
    Key? key,
    required this.userEmail,
    this.showResendButton = false,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _canResend = true;
  int _resendCountdown = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Jika showResendButton true, aktifkan tombol resend
    if (widget.showResendButton) {
      _canResend = true;
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() => _isResending = true);

    try {
      final result = await _authService.resendVerificationEmail(widget.userEmail);

      if (result['success'] == true) {
        _showSnack('Email verifikasi telah dikirim ulang', isSuccess: true);
        _startResendCooldown();
      } else {
        _showSnack('Gagal kirim ulang: ${result['message']}', isSuccess: false);
      }
    } catch (e) {
      _showSnack('Gagal kirim ulang: ${e.toString()}', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startResendCooldown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60; // 60 detik cooldown
    });

    // Countdown timer
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCooldown();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verifikasi Email'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon email
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

              // Title
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

              // Subtitle
              Text(
                'Kami telah mengirim email verifikasi ke:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Email address
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

              // Instructions
              Text(
                'Silakan cek email Anda dan klik link verifikasi untuk mengaktifkan akun. Jika tidak ada di inbox, coba cek folder spam.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Resend button
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

              // Back to login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
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
>>>>>>> 05e67f0c834ee23d192961839ad07fb6bf6a0fa8
}