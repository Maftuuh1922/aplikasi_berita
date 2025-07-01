// FILE: lib/models/comment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String articleIdentifier;
  final String author;
  final String text;
  final DateTime timestamp;
  final String? userId;

  Comment({
    required this.id,
    required this.articleIdentifier,
    required this.author,
    required this.text,
    required this.timestamp,
    this.userId,
  });

  // Factory untuk membuat objek Comment dari data Firestore
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      articleIdentifier: data['article_identifier'] ?? '',
      author: data['author'] ?? 'Anonim',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['user_id'],
    );
  }

  // Method untuk mengubah objek Comment menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'article_identifier': articleIdentifier,
      'author': author,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'user_id': userId,
    };
  }
}