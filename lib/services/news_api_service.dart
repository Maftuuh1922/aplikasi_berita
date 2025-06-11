// lib/services/news_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsApiService {
  final String _baseUrl = 'https://gnews.io/api/v4';
  final String _apiKey = 'dd786b5031ee9e3a759ff31bf217c41f'; // <--- PASTIKAN SUDAH INI API KEYNYA

  Future<List<Article>> fetchTopHeadlines({String lang = 'id', String country = 'id', String topic = 'breaking-news'}) async {
    final uri = Uri.parse('$_baseUrl/top-headlines?lang=$lang&country=$country&topic=$topic&token=$_apiKey');

    print('Fetching news from GNews URL: $uri');

    try {
      final response = await http.get(uri);

      print('GNews Response Status Code: ${response.statusCode}');
      print('GNews Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['articles'] != null) {
          final List<dynamic> articleList = data['articles'];
          return articleList.map((json) => Article.fromJson(json)).toList();
        } else {
          throw Exception('GNews API response did not contain articles. Body: ${response.body}');
        }
      } else {
        throw Exception('Failed to load articles from GNews. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Caught error during GNews fetch: $e');
      throw Exception('Error fetching articles from GNews: $e');
    }
  }
}