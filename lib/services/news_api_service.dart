import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsApiService {
  final String _baseUrl = 'https://gnews.io/api/v4';
  // GANTI DENGAN API KEY BARU ANDA DARI GNEWS.IO
  final String _apiKey = 'GANTI_DENGAN_API_KEY_ANDA';

  Future<List<Article>> fetchNews({String category = 'general'}) async {
    if (_apiKey == 'GANTI_DENGAN_API_KEY_ANDA') {
      throw Exception('Ganti API Key di news_api_service.dart');
    }
    final uri = Uri.parse('$_baseUrl/top-headlines?topic=$category&lang=en&token=$_apiKey');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articles = data['articles'] ?? [];
        return articles.map((json) => Article.fromGNews(json)).toList();
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