import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class BeritaIndoApiService {
  // Mengarah ke rute daftar berita di backend Anda
  final String _baseUrl = 'https://icbs.my.id/api/news/cnn-news';

  Future<List<Article>> fetchNews({String category = 'terbaru'}) async {
    final fullUrl = '$_baseUrl/$category';

    try {
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articles = data['data'];
        return articles.map((json) => Article.fromBeritaIndo(json)).toList();
      } else {
        throw Exception('API Error (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Gagal mengambil daftar berita: $e');
    }
  }
}
