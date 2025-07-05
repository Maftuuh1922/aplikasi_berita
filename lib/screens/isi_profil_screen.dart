import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../services/auth_service.dart';

class IsiProfilScreen extends StatefulWidget {
  const IsiProfilScreen({super.key});

  @override
  State<IsiProfilScreen> createState() => _IsiProfilScreenState();
}

class _IsiProfilScreenState extends State<IsiProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _bioController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  String? _photoUrl; // URL foto profil dari backend

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final jwt = await AuthService().token;
      if (jwt == null) throw Exception('Token kosong');

      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/profile'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _namaController.text = data['nama'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _photoUrl = data['photoUrl'];
        });
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pilihGambar() async {
    final pic = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pic != null) setState(() => _imageFile = File(pic.path));
  }

  Future<String?> _uploadImage(File file) async {
    final jwt = await AuthService().token;
    if (jwt == null) throw Exception('Token kosong');

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${AuthService.baseUrl}/upload-profile-image'),
    )
      ..headers['Authorization'] = 'Bearer $jwt'
      ..files.add(http.MultipartFile(
        'image',
        file.openRead(),
        await file.length(),
        filename: p.basename(file.path),
      ));

    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode == 200) return jsonDecode(body)['imageUrl'];
    throw Exception(body);
  }

  Future<void> _simpanProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? photo = _photoUrl;
      if (_imageFile != null) photo = await _uploadImage(_imageFile!);

      final jwt = await AuthService().token;
      if (jwt == null) throw Exception('Token kosong');

      final res = await http.put(
        Uri.parse('${AuthService.baseUrl}/profile'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama': _namaController.text.trim(),
          'bio': _bioController.text.trim(),
          'photoUrl': photo,
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui!')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
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
        title: const Text('Lengkapi Profil'),
        centerTitle: true,
      ),
      body: _isLoading && _namaController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 30),
              _buildField(_namaController, 'Nama Lengkap', Icons.person),
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

  Widget _buildAvatar() => GestureDetector(
    onTap: _pilihGambar,
    child: Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!) as ImageProvider<Object>?
              : (_photoUrl != null ? NetworkImage(_photoUrl!) : null),
          child: _imageFile == null && _photoUrl == null
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
