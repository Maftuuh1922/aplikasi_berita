import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class BeritaIndoApiService {
  final String _baseUrl = 'https://berita-indo-api-next.vercel.app/api';

  Future<List<Article>> fetchNews({String category = 'terbaru'}) async {
    const source = 'cnn-news';
    final fullUrl = '$_baseUrl/$source/$category';

    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articles = data['data'];
        return articles.map((json) => Article.fromBeritaIndo(json)).toList();
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