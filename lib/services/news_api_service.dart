import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsApiService {
  // Mengganti URL ke GNews API
  final String _baseUrl = 'https://gnews.io/api/v4';

  // Menggunakan API Key yang Anda berikan
  final String _apiKey = '5e0546a65bcc816df391c530ac1f68a4';

  Future<List<Article>> fetchNews({String category = 'general'}) async {
    // Membuat URL yang benar untuk GNews
    final uri = Uri.parse(
        '$_baseUrl/top-headlines?country=id&category=$category&lang=id&token=$_apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // GNews mengembalikan berita di dalam 'articles'
        final List articles = data['articles'] ?? [];

        // Pastikan model Anda memiliki factory 'fromGNews' untuk ini
        return articles.map((json) => Article.fromGNews(json)).toList();
      } else {
        throw Exception('GNews API Error (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Koneksi Gagal: Periksa internet Anda.');
    } catch (e) {
      rethrow;
    }
  }
}
