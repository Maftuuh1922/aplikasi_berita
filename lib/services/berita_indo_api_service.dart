import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class BeritaIndoApiService {
  // Base URL ini mengarah ke rute /api/news di backend Anda
  final String _baseUrl = 'https://icbs.my.id/api/news';

  Future<List<Article>> fetchNews({String category = 'terbaru'}) async {
    // --- PERBAIKAN DI SINI ---
    // URL yang benar hanya menambahkan kategori, karena 'cnn-news' sudah
    // di-handle oleh backend Anda.
    final fullUrl =
        '$_baseUrl/$category'; // Contoh: https://icbs.my.id/api/news/nasional

    try {
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend Anda sepertinya mengembalikan data berita di dalam 'data.data'
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
