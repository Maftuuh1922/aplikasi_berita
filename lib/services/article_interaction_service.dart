import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/article.dart';
import 'package:flutter/foundation.dart'; // ← Tambahkan ini

class ArticleInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper untuk membuat ID dokumen yang aman dari URL
  String _getArticleId(String url) {
    var bytes = utf8.encode(url);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Mengambil data statistik artikel (suka, komentar, status simpan/suka)
  Future<Map<String, dynamic>> getArticleStats(String articleUrl, String? userId) async {
    final articleId = _getArticleId(articleUrl);
    final articleRef = _firestore.collection('articles').doc(articleId);

    try {
      final doc = await articleRef.get();
      bool isLiked = false;
      bool isSaved = false;

      if (userId != null) {
        final likeDoc = await articleRef.collection('likes').doc(userId).get();
        isLiked = likeDoc.exists;
        final saveDoc = await _firestore.collection('users').doc(userId).collection('bookmarks').doc(articleId).get();
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

  // Fungsi untuk menyukai atau batal menyukai artikel
  Future<void> toggleLike(String articleUrl, String userId, bool isCurrentlyLiked) async {
    final articleId = _getArticleId(articleUrl);
    final articleRef = _firestore.collection('articles').doc(articleId);
    final likeRef = articleRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final articleDoc = await transaction.get(articleRef);

      if (!isCurrentlyLiked) {
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        if (!articleDoc.exists) {
          transaction.set(articleRef, {'likeCount': 1}, SetOptions(merge: true));
        } else {
          transaction.update(articleRef, {'likeCount': FieldValue.increment(1)});
        }
      } else {
        transaction.delete(likeRef);
        if (articleDoc.exists) {
          transaction.update(articleRef, {'likeCount': FieldValue.increment(-1)});
        }
      }
    });
  }

  // Fungsi untuk menyimpan atau batal menyimpan artikel
  Future<void> toggleBookmark(String userId, Article article, bool isCurrentlySaved) async {
    final articleId = _getArticleId(article.url);
    final bookmarkRef = _firestore.collection('users').doc(userId).collection('bookmarks').doc(articleId);

    if (!isCurrentlySaved) {
      await bookmarkRef.set({
        'title': article.title,
        'url': article.url,
        'urlToImage': article.urlToImage,
        'sourceName': article.sourceName,
        'publishedAt': article.publishedAt,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await bookmarkRef.delete();
    }
  }

  // IMPROVED: Menambahkan komentar dengan struktur yang lebih baik
  Future<void> addComment(
    String articleUrl,
    String userId,
    String comment, {
    String? parentId,
    String? rootId,
    String? replyToUserId,
    String? replyToUsername,
    int parentDepth = 0, // Tambahkan parameter ini
  }) async {
    final articleId = _getArticleId(articleUrl);
    final articleRef = _firestore.collection('articles').doc(articleId);
    final commentRef = articleRef.collection('comments').doc();

    await commentRef.set({
      'userId': userId,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'likedBy': [],
      'parentId': parentId, // null untuk parent comment
      'rootId': rootId ?? commentRef.id, // always points to root comment
      'replyToUserId': replyToUserId,
      'replyToUsername': replyToUsername,
      'replyCount': 0,
      'depth': parentId == null ? 0 : parentDepth + 1, // unlimited depth
    });

    // Tambahkan log jika perlu
    debugPrint('Komentar ditambahkan: $comment');
  }

  // IMPROVED: Like/unlike komentar dengan optimistic update
  Future<void> toggleCommentLike(String articleUrl, String commentId, String userId) async {
    final articleId = _getArticleId(articleUrl);
    final commentRef = _firestore.collection('articles').doc(articleId).collection('comments').doc(commentId);
    
    await _firestore.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) {
        throw Exception("Komentar tidak ditemukan!");
      }

      final List<dynamic> likedBy = List.from(commentSnapshot.data()?['likedBy'] ?? []);
      
      if (likedBy.contains(userId)) {
        transaction.update(commentRef, {
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId])
        });
      } else {
        transaction.update(commentRef, {
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId])
        });
      }
    });
  }

  // Check if user liked a comment
  Stream<bool> isCommentLikedByUser(String articleUrl, String commentId, String userId) {
    final articleId = _getArticleId(articleUrl);
    return _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final List<dynamic> likedBy = List.from(snapshot.data()?['likedBy'] ?? []);
          return likedBy.contains(userId);
        });
  }

  // IMPROVED: Get parent comments only (level 0)
  Stream<QuerySnapshot> getParentComments(String articleUrl) {
    final articleId = _getArticleId(articleUrl);
    return _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .where('level', isEqualTo: 0)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // IMPROVED: Get replies for a specific comment
  Stream<QuerySnapshot> getReplies(String articleUrl, String parentId) {
    final articleId = _getArticleId(articleUrl);
    return _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .where('parentId', isEqualTo: parentId)  // ← Field filter
        .orderBy('timestamp', descending: false) // ← Order by
        .snapshots();
  }

  // Get total comment count for article
  Stream<int> getCommentCount(String articleUrl) {
    final articleId = _getArticleId(articleUrl);
    return _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete comment (optional feature)
  Future<void> deleteComment(String articleUrl, String commentId, String userId) async {
    final articleId = _getArticleId(articleUrl);
    final articleRef = _firestore.collection('articles').doc(articleId);
    final commentRef = articleRef.collection('comments').doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final commentDoc = await transaction.get(commentRef);
      if (!commentDoc.exists) {
        throw Exception("Komentar tidak ditemukan!");
      }

      final commentData = commentDoc.data() as Map<String, dynamic>;
      
      // Check if user owns the comment
      if (commentData['userId'] != userId) {
        throw Exception("Anda tidak dapat menghapus komentar orang lain!");
      }

      // Delete the comment
      transaction.delete(commentRef);
      
      // Decrement article comment count
      transaction.update(articleRef, {'commentCount': FieldValue.increment(-1)});
      
      // If this was a reply, decrement parent's reply count
      if (commentData['parentId'] != null) {
        final parentRef = articleRef.collection('comments').doc(commentData['parentId']);
        transaction.update(parentRef, {'replyCount': FieldValue.increment(-1)});
      }
    });
  }
}