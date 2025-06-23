// lib/screens/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              widget.article.description ?? '',
              style: const TextStyle(fontSize: 17, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            if (widget.article.content != null && widget.article.content!.isNotEmpty)
              Text(
                widget.article.content!,
                style: const TextStyle(fontSize: 16, height: 1.5),
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