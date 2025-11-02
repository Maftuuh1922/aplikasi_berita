import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart'; // Tambahkan ini di bagian import
import '../models/article.dart';

class CommentApiService {
  // Tidak perlu backend URL - menggunakan Firestore langsung
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper untuk generate article ID dari URL
  String _generateArticleId(String articleUrl) {
    final bytes = utf8.encode(articleUrl);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Mendapatkan artikel yang disimpan user dari Firestore
  Future<List<Map<String, dynamic>>> getSavedArticles({
    required String userId,
    required int page,
    required int limit,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('savedArticles')
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
      print('ERROR: getSavedArticles failed: $e');
      throw Exception('Failed to load saved articles: $e');
    }
  }

  /// Simpan/hapus artikel dari bookmark via Firestore
  Future<bool> saveArticle(String url, bool save, {Article? article}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: User not logged in');
        return false;
      }
      
      final articleId = _generateArticleId(url);
      
      if (save && article != null) {
        // Simpan artikel dengan data lengkap
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('savedArticles')
            .doc(articleId)
            .set({
          'url': article.url,
          'title': article.title,
          'urlToImage': article.urlToImage,
          'sourceName': article.sourceName,
          'publishedAt': article.publishedAt.toIso8601String(),
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('savedArticles')
            .doc(articleId)
            .delete();
      }
      
      return true;
    } catch (e) {
      print('ERROR: saveArticle failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> addComment(
    String articleUrl,
    String comment, {
    String? parentId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final articleId = _generateArticleId(articleUrl);
      final commentId = _firestore.collection('articles').doc(articleId).collection('comments').doc().id;
      
      final commentData = {
        'id': commentId,
        'articleUrl': articleUrl,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userPhotoUrl': user.photoURL,
        'comment': comment,
        'parentId': parentId,
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('articles')
          .doc(articleId)
          .collection('comments')
          .doc(commentId)
          .set(commentData);

      return {
        'success': true,
        'comment': {
          '_id': commentId,
          'user': {
            'name': user.displayName ?? 'Anonymous',
            'photoUrl': user.photoURL,
          },
          'comment': comment,
          'likes': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
    } catch (e) {
      print('Error posting comment: $e');
      return {
        'success': false,
        'message': 'Failed to add comment: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String articleUrl) async {
    try {
      final articleId = _generateArticleId(articleUrl);
      
      final snapshot = await _firestore
          .collection('articles')
          .doc(articleId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'articleUrl': data['articleUrl'] ?? articleUrl,
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Anonymous',
          'userPhotoUrl': data['userPhotoUrl'],
          'comment': data['comment'] ?? '',
          'parentId': data['parentId'],
          'likes': data['likes'] ?? 0,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
        };
      }).toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> likeComment(String commentId, bool like) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Cari comment di semua artikel (untuk simplifikasi)
      // Dalam produksi, sebaiknya simpan articleId juga
      final articlesSnapshot = await _firestore.collection('articles').get();
      
      for (var articleDoc in articlesSnapshot.docs) {
        final commentDoc = await articleDoc.reference
            .collection('comments')
            .doc(commentId)
            .get();
            
        if (commentDoc.exists) {
          final currentLikes = commentDoc.data()?['likes'] ?? 0;
          await commentDoc.reference.update({
            'likes': like ? currentLikes + 1 : (currentLikes > 0 ? currentLikes - 1 : 0),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          return {
            'success': true,
            'likes': like ? currentLikes + 1 : (currentLikes > 0 ? currentLikes - 1 : 0),
          };
        }
      }
      
      throw Exception('Comment not found');
    } catch (e) {
      print('Error liking comment: $e');
      throw Exception('Failed to like comment: $e');
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
}
