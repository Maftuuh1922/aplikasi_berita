// lib/screens/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
// Hapus import webview_flutter jika target web/Edge, karena tidak didukung di web
// import 'package:webview_flutter/webview_flutter.dart';
import '../models/article.dart';
import '../models/comment.dart';
import '../services/comment_firebase_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final CommentFirebaseService _commentService = CommentFirebaseService();
  bool _showFullContent = false;
  bool _isLoadingFullContent = false;
  String? _fullArticleContent;
  String? _errorMessage;

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  Future<void> _loadFullArticleContent() async {
    setState(() {
      _isLoadingFullContent = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(widget.article.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Coba berbagai selector untuk mengambil konten artikel
        String? fullContent = _extractArticleContent(document);
        
        if (fullContent != null && fullContent.trim().isNotEmpty) {
          setState(() {
            _fullArticleContent = fullContent;
            _showFullContent = true;
            _isLoadingFullContent = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Tidak dapat mengambil konten lengkap dari artikel ini.';
            _isLoadingFullContent = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat artikel. Status: ${response.statusCode}';
          _isLoadingFullContent = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error memuat artikel: $e';
        _isLoadingFullContent = false;
      });
    }
  }

  // Ganti tipe parameter menjadi dom.Document agar tidak error di web
  String? _extractArticleContent(dom.Document document) {
    // Daftar selector yang umum digunakan untuk konten artikel
    List<String> contentSelectors = [
      'article',
      '.article-content',
      '.post-content',
      '.entry-content',
      '.content',
      '.article-body',
      '.post-body',
      '.story-body',
      '.article-text',
      'main',
      '[role="main"]',
      '.main-content',
      '.detail-content',
      '.news-content',
      '.article-detail',
    ];

    for (String selector in contentSelectors) {
      final elements = document.querySelectorAll(selector);
      for (var element in elements) {
        // Hapus elemen yang tidak diinginkan
        element.querySelectorAll('script, style, nav, header, footer, .advertisement, .ads, .social-share, .related-articles').forEach((el) => el.remove());
        
        String text = element.text.trim();
        if (text.length > 200) { // Pastikan konten cukup panjang
          return text;
        }
      }
    }

    // Fallback: ambil semua paragraf
    final paragraphs = document.querySelectorAll('p');
    if (paragraphs.isNotEmpty) {
      String combinedText = paragraphs
          .map((p) => p.text.trim())
          .where((text) => text.isNotEmpty && text.length > 20)
          .join('\n\n');
      
      if (combinedText.length > 200) {
        return combinedText;
      }
    }

    return null;
  }

  void _showWebViewDialog() {
    // WebView tidak didukung di Flutter Web (Edge), tampilkan info alternatif
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('WebView Tidak Didukung'),
          content: const Text(
            'Fitur WebView hanya tersedia di aplikasi Android/iOS. '
            'Silakan gunakan tombol "Baca Artikel Lengkap di Sumber Asli" untuk membuka di browser.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? content = _fullArticleContent ?? widget.article.content;
    final String? description = widget.article.description;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Berita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (widget.article.urlToImage != null && widget.article.urlToImage!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.article.urlToImage!,
                  fit: BoxFit.cover,
                  height: 220,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: Center(child: Icon(Icons.image_not_supported, size: 70, color: Colors.grey[600])),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sumber: ${widget.article.sourceName}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(widget.article.publishedAt),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Tampilkan deskripsi jika ada
            if (description != null && description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 17, color: Colors.black87),
                ),
              ),
            
            // Tampilkan content dengan fitur "Baca Selengkapnya"
            if (content != null && content.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    maxLines: _showFullContent ? null : 10,
                    overflow: _showFullContent ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  if (!_showFullContent && !_isLoadingFullContent)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _loadFullArticleContent,
                        child: const Text(
                          'Baca Selengkapnya (Muat dari Web)',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  if (_isLoadingFullContent)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Memuat artikel lengkap...'),
                          ],
                        ),
                      ),
                    ),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _showWebViewDialog,
                            icon: const Icon(Icons.web),
                            label: const Text('Buka di WebView'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(widget.article.url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Baca Artikel Lengkap di Sumber Asli'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 10),
            // Tambahkan tombol WebView di bagian bawah juga
            ElevatedButton.icon(
              onPressed: _showWebViewDialog,
              icon: const Icon(Icons.web),
              label: const Text('Buka Artikel di WebView'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 25),
            const Divider(),
            const Text(
              'Komentar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Fitur komentar dinonaktifkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            StreamBuilder<List<Comment>>(
              stream: _commentService.getCommentsForArticle(widget.article.url),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error memuat komentar: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada komentar.'));
                } else {
                  final comments = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.author,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(comment.timestamp),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}