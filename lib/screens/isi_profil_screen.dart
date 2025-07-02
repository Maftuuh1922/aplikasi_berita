import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class IsiProfilScreen extends StatefulWidget {
  const IsiProfilScreen({super.key});

  @override
  State<IsiProfilScreen> createState() => _IsiProfilScreenState();
}

class _IsiProfilScreenState extends State<IsiProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _bioController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _namaController.text = _user!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse('https://icbs.my.id/api/upload-profile');
    final request = http.MultipartRequest('POST', uri);
    final imageStream = http.ByteStream(imageFile.openRead());
    final length = await imageFile.length();

    final multipartFile = http.MultipartFile(
      'image',
      imageStream,
      length,
      filename: p.basename(imageFile.path), // ✅ Gunakan `p.basename`
    );

    request.files.add(multipartFile);
    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['imageUrl'];
    } else {
      throw Exception("Gagal upload foto: ${response.statusCode}");
    }
  }

  Future<void> _simpanProfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus login!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _user!.photoURL;

      if (_imageFile != null) {
        photoUrl = await uploadImage(_imageFile!);
      }

      await _user!.updateDisplayName(_namaController.text.trim());
      await _user!.updatePhotoURL(photoUrl);

      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'nama': _namaController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
        'email': _user!.email,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lengkapi Profil"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pilihGambar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null) as ImageProvider?,
                        child: _imageFile == null && _user?.photoURL == null
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
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _namaController,
                label: "Nama Lengkap",
                icon: Icons.person_outline,
                hint: "Masukkan nama lengkap Anda",
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _bioController,
                label: "Bio",
                icon: Icons.info_outline,
                hint: "Ceritakan sedikit tentang diri Anda",
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanProfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Simpan Perubahan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          validator: (value) => value == null || value.isEmpty ? '$label tidak boleh kosong' : null,
        ),
      ],
    );
  }
}
