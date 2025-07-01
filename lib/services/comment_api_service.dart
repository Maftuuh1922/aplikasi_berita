import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/comment.dart';

class CommentApiService {
  // Gunakan http://10.0.2.2:3000 jika menjalankan di emulator Android
  // Gunakan http://localhost:3000 jika menjalankan di Chrome
  final String _baseUrl = 'https://icbs.my.id/api';

  // Mengambil komentar dari backend Anda
  Future<List<Comment>> fetchComments(String articleUrl) async {
    final encodedUrl = Uri.encodeComponent(articleUrl);
    final response = await http.get(Uri.parse('$_baseUrl/articles/$encodedUrl/comments'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat komentar dari server.');
    }
  }

  // Mengirim komentar ke backend Anda
  Future<Comment> postComment(String articleUrl, String author, String text) async {
    final encodedUrl = Uri.encodeComponent(articleUrl);
    final response = await http.post(
      Uri.parse('$_baseUrl/articles/$encodedUrl/comments'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'author': author, 'text': text}),
    );

    if (response.statusCode == 201) {
      return Comment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal mengirim komentar ke server.');
    }
  }
}