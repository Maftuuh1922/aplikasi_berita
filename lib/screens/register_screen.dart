// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verifikasi_email_screen.dart' show VerifikasiEmailScreen;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController(); // Controller untuk Nama Tampilan
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _displayNameCtrl.dispose(); // Dispose controller nama tampilan
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  /* ---------------- register via backend ---------------- */
  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Panggilan ke AuthService dengan urutan parameter yang benar: displayName, email, password
      final result = await _authService.registerWithEmailAndPassword(
        _displayNameCtrl.text.trim(), // Trim Nama Tampilan
        _emailCtrl.text.trim(),       // Trim Email
        _passwordCtrl.text,
      );

      if (!mounted) return;

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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

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
                    _buildPasswordField(), // Field Password
                    const SizedBox(height: 16),
                    _buildConfirmField(), // Field Konfirmasi Password
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