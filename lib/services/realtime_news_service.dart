import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class RealtimeNewsService {
  final String _baseUrl = 'https://real-time-news-data.p.rapidapi.com/topic-news-by-section';
  final String _apiKey = '7315b1df9bmsh597dc1888711a54p17af57jsne29d2fc18b4a';

  Future<List<Article>> fetchNews({
    String topic = 'GENERAL',
    int limit = 10,
    String country = 'ID',
    String lang = 'id',
  }) async {
    final uri = Uri.parse('$_baseUrl?topic=$topic&limit=$limit&country=$country&lang=$lang');

    final response = await http.get(
      uri,
      headers: {
        'x-rapidapi-key': _apiKey,
        'x-rapidapi-host': 'real-time-news-data.p.rapidapi.com',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List articles = data['data'] ?? [];
      // REVISI: Gunakan factory fromNewsApi yang sudah ada
      // Kita perlu membuat map baru agar key-nya cocok
      return articles.map((json) {
        return Article.fromNewsApi({
          'source': {'name': json['source'] ?? 'RealTimeNews'},
          'title': json['title'],
          'author': json['author'],
          'url': json['url'],
          'image': json['image_url'],
          'publishedAt': json['published_datetime'],
          'content': json['content'],
        });
      }).toList();
    } else {
      throw Exception('Failed to load berita dari RealTimeNews');
    }
  }
}