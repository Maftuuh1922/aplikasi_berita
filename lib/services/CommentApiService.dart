import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment.dart';

class CommentApiService {
  // Ganti dengan URL BASE API KOMENTAR Anda sendiri!
  final String _baseUrl = 'http://localhost:3000/api'; // Contoh: jika Anda pakai Node.js di localhost

  Future<List<Comment>> fetchCommentsForArticle(String articleIdentifier) async {
    final response = await http.get(Uri.parse('$_baseUrl/articles/$articleIdentifier/comments'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  Future<Comment> postComment(String articleIdentifier, String text, String author) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/articles/$articleIdentifier/comments'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'article_id': articleIdentifier,
        'text': text,
        'author': author,
      }),
    );

    if (response.statusCode == 201) { // 201 Created untuk sukses POST
      return Comment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to post comment: ${response.body}');
    }
  }
}