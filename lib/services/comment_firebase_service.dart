// FILE: lib/services/comment_firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';

class CommentFirebaseService {
  final CollectionReference _commentCollection =
      FirebaseFirestore.instance.collection('comments');

  /// Menambahkan komentar baru ke Firestore
  Future<void> addComment(Comment comment) async {
    // Menggunakan method toFirestore() dari model Comment
    await _commentCollection.doc(comment.id).set(comment.toFirestore());
  }

  /// Mengambil daftar komentar untuk artikel tertentu
  Future<List<Comment>> getComments(String articleUrl) async {
    final querySnapshot = await _commentCollection
        // Mencari berdasarkan field yang benar: 'article_identifier'
        .where('article_identifier', isEqualTo: articleUrl)
        .orderBy('timestamp', descending: true)
        .get();

    // Menggunakan factory fromFirestore dari model Comment
    return querySnapshot.docs
        .map((doc) => Comment.fromFirestore(doc))
        .toList();
  }
}