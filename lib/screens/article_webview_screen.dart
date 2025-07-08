import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../widgets/comment_section_popup.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({Key? key, required this.article})
      : super(key: key);

  Future<void> _openInBrowser(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw 'Tidak bisa membuka $url';
    }
  }

  void _showCommentsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) =>
            CommentSectionPopup(articleUrl: article.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simulasi konten HTML. Idealnya, ini didapat dari API.
    // Kita gabungkan gambar (jika ada) dengan deskripsi.
    final String htmlContent = '''
      ${article.urlToImage != null ? '<img src="${article.urlToImage}" alt="${article.title}" style="width:100%; height:auto; border-radius: 8px;" />' : ''}
      <p>${article.description ?? 'Tidak ada konten tambahan.'}</p>
      <p><em>Untuk membaca artikel selengkapnya, silakan buka di browser.</em></p>
    ''';

    return Scaffold(
      appBar: AppBar(
        title: Text(article.sourceName),
        actions: [
          Consumer<BookmarkService>(
            builder: (context, bookmarkService, child) {
              final isBookmarked = bookmarkService.isBookmarked(article);
              return IconButton(
                icon:
                    Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => bookmarkService.toggleBookmark(article),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _openInBrowser(article.url),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share('Baca berita ini: ${article.url}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Berita
            Text(
              article.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Info Penulis dan Tanggal
            Text(
              'Oleh ${article.author ?? 'Tidak diketahui'} ● ${article.publishedAt.toLocal().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            // Konten HTML
            Html(
              data: htmlContent,
              style: {
                "body": Style(
                  fontSize: FontSize(16.0),
                  lineHeight: LineHeight.em(1.5),
                ),
                "p": Style(margin: Margins.only(bottom: 12)),
              },
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
