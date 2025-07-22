import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/article.dart';
import 'package:flutter/foundation.dart';

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
        final saveDoc = await _firestore.collection('users').doc(userId).collection('savedArticles').doc(articleId).get();
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
    final bookmarkRef = _firestore.collection('users').doc(userId).collection('savedArticles').doc(articleId);

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

  // FIXED: Menambahkan komentar dengan struktur yang konsisten
  Future<void> addComment(
    String articleUrl,
    String userId,
    String comment, {
    String? parentId,
    String? rootId,
    String? replyToUserId,
    String? replyToUsername,
  }) async {
    int level = 0;
    if (parentId != null) {
      final articleId = _getArticleId(articleUrl);
      final parentComment = await _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(parentId)
        .get();

      if (parentComment.exists) {
        final parentLevel = parentComment.data()?['level'] ?? 0;
        // Batasi level maksimal 2
        level = parentLevel < 2 ? parentLevel + 1 : 2;
      } else {
        level = 1;
      }
    }

    final articleId = _getArticleId(articleUrl);
    final articleRef = _firestore.collection('articles').doc(articleId);

    // Tambahkan komentar baru
    final newCommentRef = await _firestore
      .collection('articles')
      .doc(articleId)
      .collection('comments')
      .add({
        'articleUrl': articleUrl,
        'userId': userId,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'parentId': parentId,
        'rootId': rootId ?? parentId,
        'replyToUserId': replyToUserId,
        'replyToUsername': replyToUsername,
        'level': level,
      });

    // Increment commentCount pada dokumen artikel
    await articleRef.set(
      {'commentCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    // Tambahkan replyCount jika ini balasan
    if (parentId != null) {
      final parentRef = _firestore
          .collection('articles')
          .doc(articleId)
          .collection('comments')
          .doc(parentId);
      await parentRef.update({'replyCount': FieldValue.increment(1)});
    }
  }

  // FIXED: Like/unlike komentar dengan optimistic update
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

  // FIXED: Get parent comments only (level 0)
  Stream<QuerySnapshot> getParentComments(String articleUrl) {
    final articleId = _getArticleId(articleUrl);
    return _firestore
      .collection('articles')
      .doc(articleId)
      .collection('comments')
      .where('level', isEqualTo: 0)
      .orderBy('timestamp', descending: false)
      .snapshots();
  }

  // Ganti dari parentId ke rootId agar semua balasan (nested) bisa diambil
  Stream<QuerySnapshot> getReplies(String articleUrl, String rootId) {
    final articleId = _getArticleId(articleUrl);
    return _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .where('rootId', isEqualTo: rootId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // DEBUG: Method untuk cek data comment secara manual
  Future<void> debugCommentCount(String articleUrl) async {
    final articleId = _getArticleId(articleUrl);
    
    try {
      print('=== DEBUG COMMENT COUNT ===');
      print('Article URL: $articleUrl');
      print('Article ID (hashed): $articleId');
      
      // Cek dokumen artikel
      final articleDoc = await _firestore.collection('articles').doc(articleId).get();
      print('Article document exists: ${articleDoc.exists}');
      if (articleDoc.exists) {
        print('Article data: ${articleDoc.data()}');
      }
      
      // Cek koleksi komentar
      final commentsQuery = await _firestore
          .collection('articles')
          .doc(articleId)
          .collection('comments')
          .get();
          
      print('Total comments found: ${commentsQuery.docs.length}');
      
      // Print semua komentar
      for (var doc in commentsQuery.docs) {
        print('Comment ${doc.id}: ${doc.data()}');
      }
      
      print('=== END DEBUG ===');
    } catch (e) {
      print('DEBUG ERROR: $e');
    }
  }

  // Method untuk menambah comment count ke artikel (jika belum ada)
  Future<void> updateArticleCommentCount(String articleUrl) async {
    final articleId = _getArticleId(articleUrl);
    final articleRef = _firestore.collection('articles').doc(articleId);
    
    try {
      // Hitung total komentar
      final commentsQuery = await articleRef.collection('comments').get();
      final totalComments = commentsQuery.docs.length;
      
      // Update atau create document artikel dengan comment count
      await articleRef.set({
        'commentCount': totalComments,
        'url': articleUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Updated article comment count to: $totalComments');
    } catch (e) {
      print('Error updating comment count: $e');
    }
  }

  // FIXED: Method getCommentCount yang lebih robust
  Stream<int> getCommentCount(String articleUrl) {
    final articleId = _getArticleId(articleUrl);
    
    return _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.length;
          print('Real-time comment count for $articleUrl: $count'); // Debug
          return count;
        })
        .handleError((error) {
          print('Error in getCommentCount stream: $error');
          return 0;
        });
  }

  // Delete comment (optional feature)
  Future<void> deleteComment(String articleUrl, String commentId) async {
    try {
      final articleId = _getArticleId(articleUrl); // GUNAKAN INI!
      await FirebaseFirestore.instance
          .collection('articles')
          .doc(articleId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      debugPrint('ERROR: Gagal menghapus komentar $commentId: $e');
      throw Exception('Gagal menghapus komentar: $e');
    }
  }

  Future<void> deleteCommentWithReplies(String articleUrl, String commentId) async {
    debugPrint('DEBUG: Menghapus root comment $commentId dan semua balasannya pada artikel $articleUrl');
    final articleId = _getArticleId(articleUrl); // GUNAKAN INI!
    final batch = FirebaseFirestore.instance.batch();
    final repliesQuery = await FirebaseFirestore.instance
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .where('rootId', isEqualTo: commentId)
        .get();
    for (var reply in repliesQuery.docs) {
      debugPrint('DEBUG: Menghapus reply ${reply.id}');
      batch.delete(reply.reference);
    }
    final commentRef = FirebaseFirestore.instance
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);
    batch.delete(commentRef);
    await batch.commit();
    debugPrint('DEBUG: Semua balasan dan root comment $commentId berhasil dihapus');
  }

  // Get comments by parentId (optional feature)
  Stream<QuerySnapshot> getCommentsWithParentId(String articleUrl, String parentId) {
    final articleId = _getArticleId(articleUrl);
    return _firestore
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .where('parentId', isEqualTo: parentId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> removeBookmark(String userId, String articleUrl) async {
    final articleId = _getArticleId(articleUrl);
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('savedArticles')
      .doc(articleId)
      .delete();
  }
}