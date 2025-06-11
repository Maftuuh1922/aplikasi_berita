// lib/models/article.dart
class Article {
  final String sourceName;
  final String? author;
  final String title;
  final String? description;
  final String url;
  final String? urlToImage; // Changed from imageUrl to urlToImage
  final DateTime publishedAt;
  final String? content;

  Article({
    required this.sourceName,
    this.author,
    required this.title,
    this.description,
    required this.url,
    this.urlToImage, // Changed from imageUrl to urlToImage
    required this.publishedAt,
    this.content,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      sourceName: json['source']['name'] ?? 'Unknown Source',
      author: json['author'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      url: json['url'] ?? '',
      urlToImage: json['image'], // Changed from imageUrl to urlToImage, but keep using 'image' from JSON
      publishedAt: DateTime.parse(json['publishedAt']),
      content: json['content'],
    );
  }
}