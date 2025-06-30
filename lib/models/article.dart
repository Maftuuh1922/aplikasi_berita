// lib/models/article.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/realtime_news_service.dart' as rtnews;

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
    // Deteksi struktur GNews (ada 'source') atau Berita Indo (tidak ada 'source')
    if (json.containsKey('source')) {
      // GNews
      return Article(
        sourceName: json['source']['name'] ?? 'Unknown Source',
        author: json['author'],
        title: json['title'] ?? 'No Title',
        description: json['description'],
        url: json['url'] ?? '',
        urlToImage: json['image'],
        publishedAt: DateTime.parse(json['publishedAt']),
        content: json['content'],
      );
    } else {
      // Berita Indo API
      return Article(
        sourceName: 'Berita Indonesia',
        author: null,
        title: json['title'] ?? 'No Title',
        description: json['description'],
        url: json['link'] ?? '',
        urlToImage: json['image'],
        publishedAt: DateTime.tryParse(json['pubDate'] ?? '') ?? DateTime.now(),
        content: null,
      );
    }
  }

  factory Article.fromContextualWeb(Map<String, dynamic> json) {
    return Article(
      sourceName: json['provider']?['name'] ?? 'ContextualWeb',
      author: null,
      title: json['title'] ?? 'No Title',
      description: json['description'],
      url: json['url'] ?? '',
      urlToImage: json['image']?['url'] ?? '',
      publishedAt: DateTime.tryParse(json['datePublished'] ?? '') ?? DateTime.now(),
      content: json['body'] ?? '',
    );
  }

  factory Article.fromRealtimeNews(Map<String, dynamic> json) {
    return Article(
      sourceName: json['source'] ?? 'RealTimeNews',
      author: json['author'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      url: json['url'] ?? '',
      urlToImage: json['image_url'] ?? '',
      publishedAt: DateTime.tryParse(json['published_datetime'] ?? '') ?? DateTime.now(),
      content: json['content'] ?? '',
    );
  }

  factory Article.fromNewsApi(Map<String, dynamic> json) {
    return Article(
      sourceName: json['source']['name'] ?? 'GNews',
      author: json['author'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      url: json['url'] ?? '',
      urlToImage: json['image'] ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      content: json['content'] ?? '',
    );
  }

  static Future<List<Article>> fetchArticlesFromContextualWeb(String apiUrl) async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('API RESPONSE: $data'); // Tambahkan ini
      final List articles = data['value'];
      print('ARTICLES: $articles'); // Tambahkan ini
      return articles.map((json) => Article.fromContextualWeb(json)).toList();
    } else {
      throw Exception('Failed to load articles');
    }
  }

  static Future<List<Article>> fetchIndoNews(String query, int page, int pageSize) async {
    final apiUrl = 'https://api.contextualwebsearch.com/v1/news/search?'
        'apikey=YOUR_API_KEY'
        '&q=$query'
        '&page=$page'
        '&pageSize=$pageSize';

    return await fetchArticlesFromContextualWeb(apiUrl);
  }

  static Future<List<Article>> fetchRealtimeNews() async {
    return await rtnews.RealtimeNewsService().fetchNews(
      topic: 'GENERAL',
      limit: 10,
      country: 'ID',
      lang: 'id',
    );
  }
}