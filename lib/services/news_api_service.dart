import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsApiService {
  final String _baseUrl = 'https://icbs.my.id/api/news';

  Future<List<Article>> fetchNews(String category) async {
    final uri = Uri.parse('$_baseUrl/$category');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List articles = json.decode(response.body);
        return articles.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception('API Error (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Koneksi Gagal: Periksa internet Anda.');
    } catch (e) {
      rethrow;
    }
  }
}
