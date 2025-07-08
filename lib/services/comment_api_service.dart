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
    try {
      final encodedUrl = Uri.encodeComponent(articleUrl);
      final response = await http.get(
        Uri.parse('$_baseUrl/articles/$encodedUrl/comments'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat komentar dari server.');
      }
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  // Mengirim komentar ke backend Anda
  Future<Comment> postComment(
      String articleUrl, String author, String text) async {
    try {
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
    } catch (e) {
      throw Exception('Error posting comment: $e');
    }
  }

  // Mengirim balasan untuk komentar
  Future<Comment> postReply(
      String parentCommentId, String author, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/comments/$parentCommentId/replies'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'author': author,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        return Comment.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal mengirim balasan ke server.');
      }
    } catch (e) {
      throw Exception('Error posting reply: $e');
    }
  }

  // Like/Unlike komentar
  Future<Map<String, dynamic>> likeComment(String commentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/comments/$commentId/like'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal menyukai komentar.');
      }
    } catch (e) {
      throw Exception('Error liking comment: $e');
    }
  }

  // Like/Unlike artikel
  Future<Map<String, dynamic>> likeArticle(
      String articleUrl, bool isLiked) async {
    try {
      final encodedUrl = Uri.encodeComponent(articleUrl);
      final response = await http.post(
        Uri.parse('$_baseUrl/articles/$encodedUrl/like'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'isLiked': isLiked,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal menyukai artikel.');
      }
    } catch (e) {
      throw Exception('Error liking article: $e');
    }
  }

  // Simpan/Unsave artikel
  Future<Map<String, dynamic>> saveArticle(
      String articleUrl, bool isSaved) async {
    try {
      final encodedUrl = Uri.encodeComponent(articleUrl);
      final response = await http.post(
        Uri.parse('$_baseUrl/articles/$encodedUrl/save'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'isSaved': isSaved,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal menyimpan artikel.');
      }
    } catch (e) {
      throw Exception('Error saving article: $e');
    }
  }

  // Bagikan artikel
  Future<Map<String, dynamic>> shareArticle(String articleUrl) async {
    try {
      final encodedUrl = Uri.encodeComponent(articleUrl);
      final response = await http.post(
        Uri.parse('$_baseUrl/articles/$encodedUrl/share'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal membagikan artikel.');
      }
    } catch (e) {
      throw Exception('Error sharing article: $e');
    }
  }

  // Mendapatkan statistik artikel (like count, save count, share count)
  Future<Map<String, dynamic>> getArticleStats(String articleUrl) async {
    try {
      final encodedUrl = Uri.encodeComponent(articleUrl);
      final response = await http.get(
        Uri.parse('$_baseUrl/articles/$encodedUrl/stats'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal mendapatkan statistik artikel.');
      }
    } catch (e) {
      throw Exception('Error getting article stats: $e');
    }
  }

  // Mendapatkan balasan untuk komentar tertentu
  Future<List<Comment>> fetchReplies(String commentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/comments/$commentId/replies'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat balasan dari server.');
      }
    } catch (e) {
      throw Exception('Error fetching replies: $e');
    }
  }

  // Hapus komentar (jika diperlukan)
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus komentar.');
      }
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }

  // Edit komentar (jika diperlukan)
  Future<Comment> editComment(String commentId, String newText) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'text': newText,
        }),
      );

      if (response.statusCode == 200) {
        return Comment.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal mengedit komentar.');
      }
    } catch (e) {
      throw Exception('Error editing comment: $e');
    }
  }
}
