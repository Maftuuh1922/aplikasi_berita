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
      _showSnack(
          'Gagal daftar: ${e.toString().replaceFirst('Exception: ', '')}');
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
      _showSnack(
          'Gagal daftar dengan Google: ${e.toString().replaceFirst('Exception: ', '')}');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildBackButton(context, isDark),
              const SizedBox(height: 16),
              _buildTitle(isDark),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildDisplayNameField(isDark),
                    const SizedBox(height: 12),
                    _buildEmailField(isDark),
                    const SizedBox(height: 12),
                    _buildPasswordField(isDark),
                    const SizedBox(height: 12),
                    _buildConfirmField(isDark),
                    const SizedBox(height: 20),
                    _buildSubmitButton(isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSeparator(isDark),
              const SizedBox(height: 20),
              _buildGoogleButton(isDark),
              const SizedBox(height: 20),
              _buildLoginLink(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _isGoogleLoading ? null : _handleGoogleRegister,
        icon: _isGoogleLoading
            ? const SizedBox.shrink()
            : Image.asset(
                'assets/google_logo.png',
                height: 18,
                width: 18,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.g_mobiledata,
                  color: isDark ? Colors.white : Colors.black,
                  size: 22,
                ),
              ),
        label: _isGoogleLoading
            ? const CircularProgressIndicator()
            : Text(
                "Daftar dengan Google",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildSeparator(bool isDark) {
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? Colors.white : Colors.black)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "ATAU",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
        ),
        Expanded(child: Divider(color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }

  Widget _buildBackButton(BuildContext ctx, bool isDark) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
      );

  Widget _buildTitle(bool isDark) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Buat Akun Baru",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Mulai perjalanan Anda dengan membuat akun.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      );

  InputDecoration _inputDec(String label, IconData icon, bool isDark) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
        filled: true,
        fillColor: isDark ? Colors.black : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white : Colors.black, width: 2),
        ),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      );

  Widget _buildEmailField(bool isDark) => TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDec('Email', Icons.email_outlined, isDark),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email wajib diisi';
          final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!regex.hasMatch(v)) return 'Format email tidak valid';
          return null;
        },
      );

  Widget _buildPasswordField(bool isDark) => TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        decoration: _inputDec('Password', Icons.lock_outline, isDark).copyWith(
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password wajib diisi';
          if (v.length < 6) return 'Password minimal 6 karakter';
          return null;
        },
      );

  Widget _buildConfirmField(bool isDark) => TextFormField(
        controller: _confirmPasswordCtrl,
        obscureText: _obscureConfirmPassword,
        decoration: _inputDec('Konfirmasi Password', Icons.lock_outline, isDark)
            .copyWith(
          suffixIcon: GestureDetector(
            onTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
            child: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
          if (v != _passwordCtrl.text) return 'Password tidak cocok';
          return null;
        },
      );

  Widget _buildDisplayNameField(bool isDark) => TextFormField(
        controller: _displayNameCtrl,
        keyboardType: TextInputType.text,
        decoration: _inputDec('Nama Tampilan', Icons.person_outline, isDark),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Nama Tampilan wajib diisi';
          return null;
        },
      );

  Widget _buildSubmitButton(bool isDark) => SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleEmailRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.white : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                )
              : const Text("Daftar dengan Email",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _buildLoginLink(BuildContext ctx, bool isDark) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Sudah punya akun? ",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Text(
              "Masuk",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
}
