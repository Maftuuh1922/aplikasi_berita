// lib/screens/isi_profil_screen.dart
import 'dart:convert';
import 'dart:io'; // Tetap import ini untuk platform mobile, tapi akan dihindari di web
import 'dart:typed_data'; // Untuk MemoryImage di web

import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../services/auth_service.dart'; // Pastikan AuthService diimpor

class IsiProfilScreen extends StatefulWidget {
  // Pastikan constructor ini menggunakan 'const' dan 'super.key'
  const IsiProfilScreen({super.key}); // <-- PERHATIKAN: 'const' dan 'super.key'

  @override
  State<IsiProfilScreen> createState() => _IsiProfilScreenState();
}

class _IsiProfilScreenState extends State<IsiProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController(); // Untuk Nama Tampilan
  final _bioController = TextEditingController(); // Ini tetap sebagai placeholder jika tidak ada di backend

  XFile? _imageFile; // <-- UBAH TIPE INI menjadi XFile
  bool _isLoading = false;

  String? _photoUrl; // URL foto profil dari backend
  AppUser? _currentUser; // Untuk menyimpan data user saat ini yang dimuat

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Muat data profil saat initState
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat data profil pengguna saat ini
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[IsiProfilScreen] _loadUserProfile: Memanggil AuthService().getCurrentUser()');
      final AppUser? user = await AuthService().getCurrentUser(); // Ambil user dari AuthService
      
      if (user == null) {
        // Jika tidak ada user atau sesi berakhir, mungkin arahkan ke login
        debugPrint('[IsiProfilScreen] _loadUserProfile: Pengguna null atau tidak ditemukan.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesi berakhir atau pengguna tidak ditemukan. Silakan login ulang.')),
          );
          // Opsional: Navigator.of(context).pushReplacementNamed('/login'); // Jika ingin langsung ke login
        }
        return;
      }

      // --- TAMBAHAN DEBUG PRINT DI SINI ---
      debugPrint('[IsiProfilScreen] _loadUserProfile: User object received: ${user.toJson()}');
      debugPrint('[IsiProfilScreen] _loadUserProfile: user.displayName from object: "${user.displayName}"');
      // --- AKHIR TAMBAHAN DEBUG PRINT ---

      setState(() {
        _currentUser = user;
        _displayNameController.text = user.displayName ?? ''; // Set dari displayName
        // _bioController.text = user.bio ?? ''; // Uncomment jika ada field 'bio' di AppUser dan diisi dari JWT
        _photoUrl = user.photoUrl; // Set photoUrl dari user
      });
      debugPrint('[IsiProfilScreen] _loadUserProfile: Nama Lengkap di controller setelah setState: "${_displayNameController.text}"');
      debugPrint('[IsiProfilScreen] _loadUserProfile: Photo URL di controller setelah setState: "${_photoUrl}"');

    } catch (e) {
      debugPrint('[IsiProfilScreen] _loadUserProfile gagal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pilihGambar() async {
    final pic = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pic != null) {
      setState(() => _imageFile = pic); // <-- Simpan XFile langsung
    }
  }

  // Fungsi untuk mengupload gambar ke backend
  // Menerima XFile sebagai parameter untuk kompatibilitas web
  Future<String?> _uploadImage(XFile file) async {
    final jwt = await AuthService().token;
    if (jwt == null) throw Exception('Token kosong. Silakan login ulang.');

    final bytes = await file.readAsBytes(); // Baca bytes dari XFile, kompatibel untuk web
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${AuthService.baseUrl}/upload-profile-image'),
    )
      ..headers['Authorization'] = 'Bearer $jwt'
      ..files.add(http.MultipartFile.fromBytes( // <-- Gunakan fromBytes
        'image', // Nama field di backend untuk file gambar (misal: req.files.image)
        bytes,
        filename: file.name, // Gunakan file.name dari XFile
      ));

    final resp = await req.send();
    final body = await resp.stream.bytesToString();

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(body);
      return data['imageUrl']; // Sesuaikan key 'imageUrl' jika backend Anda menggunakan key yang berbeda.
    } else {
      throw Exception('Gagal upload gambar: ${resp.statusCode} - $body');
    }
  }

  // Fungsi untuk menyimpan perubahan profil
  Future<void> _simpanProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? finalPhotoUrl = _photoUrl; // Default ke photoUrl yang sudah ada
      if (_imageFile != null) {
        // Jika ada gambar baru dipilih, upload dulu (panggil _uploadImage dengan XFile)
        finalPhotoUrl = await _uploadImage(_imageFile!);
      }

      // Panggil AuthService untuk memperbarui profil di backend
      final bool success = await AuthService().updateProfile(
        displayName: _displayNameController.text.trim(),
        photoUrl: finalPhotoUrl,
        // bio: _bioController.text.trim(), // Uncomment jika field 'bio' sudah ada di backend dan AppUser
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui!')),
          );
          Navigator.pop(context); // Kembali ke ProfileScreen
        }
      } else {
        throw Exception('Gagal memperbarui profil melalui AuthService');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan CircularProgressIndicator jika sedang loading dan belum ada data user
    if (_isLoading && _currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lengkapi Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Selalu tampilkan SingleChildScrollView untuk menghindari error overflow
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 30),
              _buildField(_displayNameController, 'Nama Lengkap', Icons.person),
              const SizedBox(height: 20),
              _buildField(_bioController, 'Bio', Icons.info, maxLines: 3),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanProfil,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Perubahan'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk menampilkan avatar dan tombol ganti foto (disesuaikan untuk web & mobile)
  Widget _buildAvatar() {
    ImageProvider<Object>? backgroundImage;

    // Tampilkan gambar dari _imageFile jika ada (baru dipilih)
    if (_imageFile != null) {
      if (kIsWeb) {
        // Untuk web, kita bisa langsung pakai path XFile sebagai URL blob
        backgroundImage = NetworkImage(_imageFile!.path);
      } else {
        // Untuk mobile, kita bisa pakai FileImage
        backgroundImage = FileImage(File(_imageFile!.path));
      }
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      // Tampilkan gambar dari _photoUrl jika ada (dari backend)
      backgroundImage = NetworkImage(_photoUrl!);
    }

    return GestureDetector(
      onTap: _pilihGambar,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: backgroundImage, // Gunakan backgroundImage yang sudah diputuskan
            child: backgroundImage == null // Jika tidak ada gambar, tampilkan Icon default
                ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembangun field input teks
  Widget _buildField(TextEditingController c, String label, IconData icon,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          maxLines: maxLines,
          validator: (v) =>
              v == null || v.isEmpty ? '$label tidak boleh kosong' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }
}