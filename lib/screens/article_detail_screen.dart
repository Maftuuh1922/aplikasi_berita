import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../widgets/comment_section_popup.dart';
import '../services/article_interaction_service.dart';

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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon, 
              color: iconColor ?? Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
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
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 50),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Tombol Suka
              StreamBuilder<Map<String, dynamic>>(
                stream: _getLikeStream(),
                builder: (context, snapshot) {
                  final likeCount = snapshot.data?['likeCount'] ?? 0;
                  final isLiked = snapshot.data?['isLiked'] ?? false;
                  
                  return _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'Suka',
                    count: likeCount,
                    iconColor: isLiked ? Colors.red : Colors.grey[600],
                    onTap: () {
                      // Implement like functionality here
                      // _toggleLike();
                    },
                  );
                },
              ),

              // Tombol Komentar - FIXED
              StreamBuilder<int>(
                stream: ArticleInteractionService().getCommentCount(article.url),
                builder: (context, snapshot) {
                  final commentCount = snapshot.data ?? 0;
                  print('Comment count stream: $commentCount'); // Debug print
                  
                  return _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Komentar',
                    count: commentCount,
                    onTap: () {
                      _showCommentsPopup(context);
                    },
                  );
                },
              ),

              // Tombol Simpan
              StreamBuilder<Map<String, dynamic>>(
                stream: _getBookmarkStream(),
                builder: (context, snapshot) {
                  final isSaved = snapshot.data?['isSaved'] ?? false;
                  
                  return _buildActionButton(
                    icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                    label: 'Simpan',
                    count: 0, // Bookmark biasanya tidak ada counter
                    iconColor: isSaved ? Colors.blue : Colors.grey[600],
                    onTap: () {
                      // Implement bookmark functionality here
                      // _toggleBookmark();
                    },
                  );
                },
              ),

              // Tombol Bagikan
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Bagikan',
                count: 0, // Share tidak ada counter
                onTap: () {
                  // Implement share functionality here
                  // _shareArticle();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method untuk stream like data
  Stream<Map<String, dynamic>> _getLikeStream() {
    // Implement this based on your user authentication
    // For now, return empty stream
    return Stream.value({'likeCount': 0, 'isLiked': false});
  }

  // Helper method untuk stream bookmark data  
  Stream<Map<String, dynamic>> _getBookmarkStream() {
    // Implement this based on your user authentication
    // For now, return empty stream
    return Stream.value({'isSaved': false});
  }
}