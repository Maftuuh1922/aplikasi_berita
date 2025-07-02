import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

Future<String?> uploadImage(File imageFile) async {
  final uri = Uri.parse('https://icbs.my.id/api/upload-profile');
  final request = http.MultipartRequest('POST', uri);

  final imageStream = http.ByteStream(imageFile.openRead());
  final length = await imageFile.length();

  final multipartFile = http.MultipartFile(
    'image',
    imageStream,
    length,
    filename: basename(imageFile.path),
  );

  request.files.add(multipartFile);

  final response = await request.send();

  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final json = jsonDecode(respStr);
    return json['imageUrl']; // URL dari backend
  } else {
    throw Exception("Gagal upload foto: ${response.statusCode}");
  }
}
