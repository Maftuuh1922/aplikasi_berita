import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart'; // Tambahkan ini di bagian import

class CommentApiService {
  // Ganti dengan URL backend kamu
  static const String baseUrl = 'https://your-actual-backend-url.com/api';

  /// Helper: Ambil headers dengan Firebase ID token
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final token = await user.getIdToken(true);
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Mendapatkan artikel yang disimpan user dari backend
  Future<List<Map<String, dynamic>>> getSavedArticles({
    required String userId,
    required int page,
    required int limit,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$baseUrl/saved').replace(queryParameters: {
        'userId': userId,
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: headers);
      print('DEBUG: getSavedArticles status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['articles'] ?? []);
      } else {
        throw Exception('Failed to load saved articles: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: getSavedArticles failed: $e');
      throw Exception('Failed to load saved articles: $e');
    }
  }

  /// Simpan/hapus artikel dari bookmark via backend
  Future<bool> saveArticle(String url, bool save) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: User not logged in');
        return false;
      }
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/saved'),
        headers: headers,
        body: jsonEncode({
          'userId': user.uid,
          'url': url,
          'save': save,
        }),
      );
      print('DEBUG: saveArticle status: ${response.statusCode}');
      print('DEBUG: saveArticle response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('ERROR: saveArticle failed: $e');
      return false;
    }
  }

  /// Alternatif: Simpan/hapus artikel langsung ke Firestore
  Future<bool> saveArticleToFirestore(String url, bool save) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final articleId = _getArticleId(url);
      if (save) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedArticles')
            .doc(articleId)
            .set({
          'url': url,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedArticles')
            .doc(articleId)
            .delete();
      }
      return true;
    } catch (e) {
      print('ERROR: saveArticleToFirestore failed: $e');
      return false;
    }
  }

  /// Alternatif: Ambil artikel tersimpan dari Firestore
  Future<List<Map<String, dynamic>>> getSavedArticlesFromFirestore({
    required String userId,
    required int page,
    required int limit,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedArticles') // <-- GANTI INI!
          .orderBy('savedAt', descending: true)
          .limit(limit);

      if (page > 1) {
        query = query.limit(limit * page);
      }

      final querySnapshot = await query.get();
      final articles = querySnapshot.docs
          .skip((page - 1) * limit)
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return {
              'url': data?['url'] ?? '',
              'title': data?['title'] ?? '',
              'urlToImage': data?['urlToImage'] ?? '',
              'sourceName': data?['sourceName'] ?? '',
              'publishedAt': data?['publishedAt'],
              'savedAt': data?['savedAt'],
            };
          })
          .toList();

      return articles;
    } catch (e) {
      print('ERROR: getSavedArticlesFromFirestore failed: $e');
      throw Exception('Failed to load saved articles: $e');
    }
  }

  Future<Map<String, dynamic>> addComment(
    String articleUrl,
    String comment, {
    String? parentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/comments'),
      headers: headers,
      body: jsonEncode({
        'articleUrl': articleUrl,
        'comment': comment,
        if (parentId != null) 'parentId': parentId,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String articleUrl) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/comments?articleUrl=$articleUrl'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['comments'] ?? []);
    } else {
      throw Exception('Failed to get comments: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> likeComment(String commentId, bool like) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/comments/$commentId/like'),
      headers: headers,
      body: jsonEncode({'like': like}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to like comment: ${response.body}');
    }
  }

  Future<void> debugTokenStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('DEBUG: User not logged in');
      return;
    }
    final token = await user.getIdToken(true);
    print('DEBUG: Firebase ID token: $token');
  }

  Future<Map<String, dynamic>> getArticleStats(String articleUrl, String? userId) async {
    try {
      final articleId = Uri.encodeComponent(articleUrl);
      final articleRef = FirebaseFirestore.instance.collection('articles').doc(articleId);
      final doc = await articleRef.get();

      bool isLiked = false;
      bool isSaved = false;

      if (userId != null) {
        final likeDoc = await articleRef.collection('likes').doc(userId).get();
        isLiked = likeDoc.exists;
        final saveDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('savedArticles')
            .doc(articleId)
            .get();
        isSaved = saveDoc.exists;
      }

      if (doc.exists) {
        return {
          'likeCount': doc.data()?['likeCount'] ?? 0,
          'commentCount': doc.data()?['commentCount'] ?? 0,
          'isLiked': isLiked,
          'isSaved': isSaved,
        };
      } else {
        return {
          'likeCount': 0,
          'commentCount': 0,
          'isLiked': false,
          'isSaved': false,
        };
      }
    } catch (e) {
      print("Error getting article stats: $e");
      return {
        'likeCount': 0,
        'commentCount': 0,
        'isLiked': false,
        'isSaved': false,
      };
    }
  }

  Future<void> likeArticle(String articleUrl, String userId, bool like) async {
    final articleId = Uri.encodeComponent(articleUrl);
    final articleRef = FirebaseFirestore.instance.collection('articles').doc(articleId);
    final likeRef = articleRef.collection('likes').doc(userId);

    if (like) {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await articleRef.set({'likeCount': FieldValue.increment(1)}, SetOptions(merge: true));
    } else {
      await likeRef.delete();
      await articleRef.set({'likeCount': FieldValue.increment(-1)}, SetOptions(merge: true));
    }
  }

  /// Helper: Generate SHA1 hash dari URL untuk document ID
  String _getArticleId(String url) {
    final bytes = utf8.encode(url);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
