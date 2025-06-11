// lib/services/comment_firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';

class CommentFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Digunakan jika Anda ingin autentikasi

  // Mengambil komentar untuk artikel tertentu
  Stream<List<Comment>> getCommentsForArticle(String articleIdentifier) {
    // Penting: Bersihkan articleIdentifier untuk digunakan sebagai ID dokumen Firestore
    String cleanIdentifier = articleIdentifier.replaceAll(RegExp(r'[.#$/\[\]]'), '_');

    return _firestore
        .collection('articles')
        .doc(cleanIdentifier)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromFirestore(doc))
            .toList());
  }

  // Memposting komentar baru
  Future<void> addComment({
    required String articleIdentifier,
    required String text,
    required String author,
  }) async {
    String? userId = _auth.currentUser?.uid; // Dapatkan UID pengguna jika login

    // Penting: Bersihkan articleIdentifier untuk digunakan sebagai ID dokumen Firestore
    String cleanIdentifier = articleIdentifier.replaceAll(RegExp(r'[.#$/\[\]]'), '_');

    Comment newComment = Comment(
      id: '', // Firestore akan menggenerate ID
      articleIdentifier: cleanIdentifier, // Simpan identifier yang bersih
      author: author,
      text: text,
      timestamp: DateTime.now(),
      userId: userId,
    );

    await _firestore
        .collection('articles')
        .doc(cleanIdentifier)
        .collection('comments')
        .add(newComment.toFirestore());
  }

  // Opsional: Untuk login anonim jika Anda ingin semua orang bisa berkomentar tanpa registrasi
  Future<User?> signInAnonymously() async {
    UserCredential userCredential = await _auth.signInAnonymously();
    return userCredential.user;
  }
}