import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class BeritaIndoApiService {
  final String _baseUrl = 'https://berita-indo-api-next.vercel.app/api';

  Future<List<Article>> fetchAntaraNews() async {
    final response = await http.get(Uri.parse('$_baseUrl/antara-news/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List articles = data['data'];
      return articles.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load berita');
    }
  }

  Future<List<Article>> fetchCnnNews() async {
    final response = await http.get(Uri.parse('$_baseUrl/cnn-news/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List articles = data['data'];
      return articles.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load berita');
    }
  }
}