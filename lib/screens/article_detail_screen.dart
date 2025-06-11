// lib/screens/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../models/comment.dart';
import '../services/comment_firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final CommentFirebaseService _commentService = CommentFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Komentar tidak boleh kosong.')),
      );
      return;
    }

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda harus login dengan Google untuk memposting komentar.')),
      );
      return;
    }

    String authorName = currentUser.displayName ?? currentUser.email ?? 'Pengguna Google';

    try {
      await _commentService.addComment(
        articleIdentifier: widget.article.url,
        text: _commentController.text.trim(),
        author: authorName,
      );
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Komentar berhasil diposting!')),
      );
    } catch (e) {
      String errorMessage = 'Gagal posting komentar.';
      if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage += ' Silakan login ulang dengan Google.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      print('Error posting comment: $e');
    }
  }

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
        title: Text('Detail Berita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
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
            SizedBox(height: 15),
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
            SizedBox(height: 15),
            Text(
              widget.article.description ?? '',
              style: TextStyle(fontSize: 17, color: Colors.black87),
            ),
            SizedBox(height: 10),
            if (widget.article.content != null && widget.article.content!.isNotEmpty)
              Text(
                widget.article.content!,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(widget.article.url),
              icon: Icon(Icons.open_in_new),
              label: Text('Baca Artikel Lengkap di Sumber Asli'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
              ),
            ),
            SizedBox(height: 25),
            Divider(),
            Text(
              'Komentar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Tulis komentar Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _postComment,
                  color: Theme.of(context).primaryColor,
                ),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 15),
            StreamBuilder<List<Comment>>(
              stream: _commentService.getCommentsForArticle(widget.article.url),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error memuat komentar: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Belum ada komentar. Jadilah yang pertama!'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final comment = snapshot.data![index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.author,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: TextStyle(fontSize: 15),
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(comment.timestamp),
                                style: TextStyle(fontSize: 12, color: Colors.grey),
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