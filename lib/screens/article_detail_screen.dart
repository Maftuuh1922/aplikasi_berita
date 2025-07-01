import 'package:flutter/material.dart';
import '../models/article.dart';
import 'article_webview_screen.dart'; // Pastikan import ini ada

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tugas halaman ini hanya satu: membuka layar WebView dengan data yang benar.
    return ArticleWebviewScreen(
      article: article,
    );
  }
}