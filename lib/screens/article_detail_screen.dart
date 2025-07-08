import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../widgets/comment_section_popup.dart'; // Pastikan path ini benar

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  const ArticleDetailScreen({Key? key, required this.article})
      : super(key: key);

  void _showCommentsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        builder: (_, controller) =>
            CommentSectionPopup(articleUrl: article.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.sourceName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Berita dari API GNews
            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.urlToImage!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Judul Berita
            Text(
              article.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Info Tanggal
            Text(
              DateFormat('d MMMM yyyy, HH:mm', 'id_ID')
                  .format(article.publishedAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),

            // Konten dari API GNews
            Text(
              article.description ?? 'Konten tidak tersedia.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton.icon(
          onPressed: () => _showCommentsPopup(context),
          icon: const Icon(Icons.comment_outlined),
          label: const Text('Lihat atau Tambah Komentar'),
        ),
      ),
    );
  }
}
