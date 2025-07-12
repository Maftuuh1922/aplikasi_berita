import 'package:flutter/material.dart';
import 'package:aplikasi_berita/screens/isi_profil_screen.dart';
import '../services/auth_service.dart';
import 'verifikasi_email_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerWithEmailAndPassword(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _displayNameCtrl.text.trim(),
      );

      // Jika user berhasil dibuat, arahkan ke halaman verifikasi
      if (user != null && mounted) {
        // Perbaikan: Panggil VerifikasiEmailScreen tanpa parameter
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const VerifikasiEmailScreen(),
          ),
        );
      }
    } on Exception catch (e) {
      _showSnack('Gagal daftar: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      final bool isNewUser = result['isNewUser'] as bool;

      if (mounted) {
        if (isNewUser) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const IsiProfilScreen()),
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on Exception catch (e) {
      _showSnack('Gagal daftar dengan Google: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
              const SizedBox(height: 20),
              _buildBackButton(context),
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildDisplayNameField(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildConfirmField(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSeparator(),
              const SizedBox(height: 24),
              _buildGoogleButton(),
              const SizedBox(height: 32),
              _buildLoginLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isGoogleLoading ? null : _handleGoogleRegister,
        icon: _isGoogleLoading
            ? const SizedBox.shrink()
            : Image.asset('assets/google_logo.png', height: 24, width: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata)),
        label: _isGoogleLoading
            ? const CircularProgressIndicator()
            : const Text(
                "Daftar dengan Google",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("ATAU", style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildBackButton(BuildContext ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black54),
        ),
      );

  Widget _buildTitle() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Buat Akun Baru",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          SizedBox(height: 8),
          Text(
            "Mulai perjalanan Anda dengan membuat akun.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      );

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      );

  Widget _buildEmailField() => TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDec('Email', Icons.email_outlined),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email wajib diisi';
          final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!regex.hasMatch(v)) return 'Format email tidak valid';
          return null;
        },
      );

  Widget _buildPasswordField() => TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        decoration: _inputDec('Password', Icons.lock_outline).copyWith(
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility),
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
        decoration:
            _inputDec('Konfirmasi Password', Icons.lock_outline).copyWith(
          suffixIcon: GestureDetector(
            onTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
            child: Icon(_obscureConfirmPassword
                ? Icons.visibility_off
                : Icons.visibility),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text("Daftar dengan Email",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _buildLoginLink(BuildContext ctx) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Sudah punya akun? ",
              style: TextStyle(color: Colors.grey.shade600)),
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Text("Masuk",
                style: TextStyle(
                    color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
