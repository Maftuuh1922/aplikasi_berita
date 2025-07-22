import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan ini

class Article {
  final String sourceName;
  final String title;
  final String url;
  final String? urlToImage;
  final DateTime publishedAt;
  final String? description;
  final String? author;
  final int commentCount; // Tambahkan ini

  Article({
    required this.sourceName,
    required this.title,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    this.description,
    this.author,
    this.commentCount = 0, // Nilai default untuk commentCount
  });

  factory Article.fromBeritaIndo(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['image'] is Map<String, dynamic>) {
      imageUrl = json['image']['small'] ?? json['image']['large'];
    } else if (json['image'] is String) {
      imageUrl = json['image'];
    }
    return Article(
      sourceName: json['source'] ?? 'Berita Indonesia',
      title: json['title'] ?? 'Tanpa Judul',
      url: json['link'] ?? '',
      urlToImage: imageUrl,
      publishedAt: DateTime.tryParse(json['pubDate'] ?? '') ?? DateTime.now(),
      description: json['contentSnippet'],
      author: json['author'],
    );
  }

  factory Article.fromGNews(Map<String, dynamic> json) {
    return Article(
      sourceName: json['source']?['name'] ?? 'GNews',
      title: json['title'] ?? 'Tanpa Judul',
      url: json['url'] ?? '',
      urlToImage: json['image'],
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      description: json['description'],
      author: json['author'],
    );
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    // Perbaikan parsing publishedAt
    DateTime publishedAt;
    if (json['publishedAt'] is Timestamp) {
      publishedAt = (json['publishedAt'] as Timestamp).toDate();
    } else if (json['publishedAt'] is String) {
      publishedAt = DateTime.parse(json['publishedAt']);
    } else if (json['publishedAt'] is DateTime) {
      publishedAt = json['publishedAt'];
    } else {
      publishedAt = DateTime.now();
    }

    return Article(
      sourceName: json['source']?['name'] ?? 'Unknown',
      title: json['title'] ?? 'Tanpa Judul',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      publishedAt: publishedAt,
      description: json['description'],
      author: json['author'],
      commentCount: json['commentCount'] ?? 0, // Ambil commentCount dari json
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': {'name': sourceName},
      'title': title,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt.toIso8601String(),
      'description': description,
      'author': author,
      'commentCount': commentCount, // Tambahkan commentCount ke toJson
    };
  }
}