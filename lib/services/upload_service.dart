import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../services/auth_service.dart'; // ⬅️ ambil JWT dari sini

/// Upload foto profil ke backend Node.js
Future<String?> uploadImage(File imageFile) async {
  final jwt = await AuthService().token; // JWT yang disimpan saat login
  final uri = Uri.parse('https://icbs.my.id/api/upload-profile');

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $jwt' // kirim token
    ..files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: basename(imageFile.path),
      ),
    );

  final response = await request.send();
  if (response.statusCode == 200) {
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['imageUrl']; // URL foto yg disimpan backend
  }
  throw Exception('Gagal upload foto: ${response.statusCode}');
}
