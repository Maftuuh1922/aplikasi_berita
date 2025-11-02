import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article.dart';
import '../widgets/comment_section_popup.dart';
import '../services/article_interaction_service.dart';
import '../services/article_scraper_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailScreen({Key? key, required this.article})
      : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isLoading = true;
  String _articleContent = '';
  List<String> _articleImages = [];
  
  @override
  void initState() {
    super.initState();
    _loadArticleContent();
  }

  Future<void> _loadArticleContent() async {
    await _ensureLocale();
    
    final result = await ArticleScraperService.scrapeArticle(widget.article.url);
    
    setState(() {
      _isLoading = false;
      if (result['success'] == true && result['content'] != null) {
        final scrapedContent = result['content'] as String;
        // Gunakan hasil scraping jika lebih panjang dari description
        if (scrapedContent.length > 100) {
          _articleContent = scrapedContent;
          _articleImages = List<String>.from(result['images'] ?? []);
        } else {
          // Fallback ke description + content jika scraping kurang
          _articleContent = _buildFallbackContent();
        }
      } else {
        // Fallback jika scraping gagal
        _articleContent = _buildFallbackContent();
      }
    });
  }
  
  String _buildFallbackContent() {
    final parts = <String>[];
    
    if (widget.article.description != null && widget.article.description!.isNotEmpty) {
      parts.add(widget.article.description!);
    }
    
    // Tambahkan info bahwa konten lengkap harus dibaca di sumber asli
    if (parts.isNotEmpty) {
      parts.add('\n\nUntuk membaca artikel lengkap, silakan klik tombol "Baca Artikel Lengkap" di bawah.');
    }
    
    if (parts.isEmpty) {
      return 'Konten lengkap tidak tersedia. Silakan kunjungi sumber asli untuk membaca artikel lengkap.';
    }
    
    return parts.join('\n\n');
  }
  
  Future<void> _ensureLocale() async {
    await initializeDateFormatting('id_ID', null);
  }

  void _showCommentsPopup(BuildContext context) {
    // Cek autentikasi dulu
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog(context);
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        builder: (_, controller) =>
            CommentSectionPopup(articleUrl: widget.article.url),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.login, color: Color(0xFF6B7280)),
            SizedBox(width: 12),
            Text(
              'Login Diperlukan',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Anda harus login terlebih dahulu untuk:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.comment, size: 20, color: Color(0xFF6B7280)),
                SizedBox(width: 8),
                Text('Memberikan komentar'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite, size: 20, color: Color(0xFF6B7280)),
                SizedBox(width: 8),
                Text('Menyukai artikel'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.bookmark, size: 20, color: Color(0xFF6B7280)),
                SizedBox(width: 8),
                Text('Menyimpan artikel'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Small delay to ensure smooth transition
              await Future.delayed(const Duration(milliseconds: 100));
              if (context.mounted) {
                Navigator.pushNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Login Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _openOriginalArticle() async {
    final Uri url = Uri.parse(widget.article.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor ?? const Color(0xFF6B7280),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4F4F4F),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
        return Scaffold(
          backgroundColor: const Color(0xFFF8F4EC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F4EC),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4F4F4F)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              article.sourceName,
              style: const TextStyle(
                color: Color(0xFF4F4F4F),
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_rounded, color: Color(0xFF6B7280)),
                onPressed: () {},
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.urlToImage != null &&
                        article.urlToImage!.isNotEmpty)
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
                    Text(
                      article.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('d MMMM yyyy, HH:mm', 'id_ID')
                          .format(article.publishedAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const Divider(height: 32),
                    
                    // Loading atau Konten
                    _isLoading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFF6B7280),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Memuat artikel...',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Konten artikel
                              Text(
                                _articleContent.isNotEmpty
                                    ? _articleContent
                                    : widget.article.description ?? 'Konten tidak tersedia.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.8,
                                  color: Color(0xFF4F4F4F),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              
                              // Gambar tambahan dari scraping
                              if (_articleImages.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Gambar Terkait',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4F4F4F),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._articleImages.map((imageUrl) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container();
                                          },
                                        ),
                                      ),
                                    )),
                              ],
                              
                              const SizedBox(height: 24),
                              
                              // Tombol buka artikel asli
                              InkWell(
                                onTap: () => _openOriginalArticle(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF6B7280).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.open_in_new_rounded,
                                        color: Color(0xFF6B7280),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Baca Artikel Lengkap',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4F4F4F),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.article.sourceName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                  ],
                ),
              ),
              
              // Floating Action Bar
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5F6368).withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<Map<String, dynamic>>(
                        stream: _getLikeStream(),
                        builder: (context, snapshot) {
                          final likeCount = snapshot.data?['likeCount'] ?? 0;
                          final isLiked = snapshot.data?['isLiked'] ?? false;
                          return _buildActionButton(
                            icon: isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                            label: 'Suka',
                            count: likeCount,
                            iconColor: isLiked ? Colors.red : const Color(0xFF6B7280),
                            onTap: () {},
                          );
                        },
                      ),
                      StreamBuilder<int>(
                        stream: ArticleInteractionService()
                            .getCommentCount(widget.article.url),
                        builder: (context, snapshot) {
                          final commentCount = snapshot.data ?? 0;
                          // print('Comment count stream: $commentCount');
                          return _buildActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Komentar',
                            count: commentCount,
                            iconColor: const Color(0xFF6B7280),
                            onTap: () {
                              _showCommentsPopup(context);
                            },
                          );
                        },
                      ),
                      StreamBuilder<Map<String, dynamic>>(
                        stream: _getBookmarkStream(),
                        builder: (context, snapshot) {
                          final isSaved = snapshot.data?['isSaved'] ?? false;
                          return _buildActionButton(
                            icon: isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                            label: 'Simpan',
                            count: 0,
                            iconColor: isSaved ? const Color(0xFF5F6368) : const Color(0xFF6B7280),
                            onTap: () {},
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.share_rounded,
                        label: 'Bagikan',
                        count: 0,
                        iconColor: const Color(0xFF6B7280),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
