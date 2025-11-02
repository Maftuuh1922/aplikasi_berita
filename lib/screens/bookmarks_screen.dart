import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/comment_api_service.dart';
import '../models/article.dart';
import 'article_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final CommentApiService _commentService = CommentApiService();
  List<Article> _savedArticles = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreArticles = true;

  @override
  void initState() {
    super.initState();
    _loadSavedArticles();
  }

  Future<void> _loadSavedArticles({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreArticles = true;
        _isLoading = true;
      });
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Gunakan method Firestore
      final articles = await _commentService.getSavedArticles(
        userId: userId,
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _savedArticles =
                articles.map((data) => Article.fromJson(data)).toList();
          } else {
            _savedArticles.addAll(
                articles.map((data) => Article.fromJson(data)).toList());
          }
          _hasMoreArticles = articles.length == 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat artikel tersimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    if (!_hasMoreArticles || _isLoading) return;

    setState(() {
      _currentPage++;
    });

    await _loadSavedArticles();
  }

  Future<void> _removeFromSaved(Article article) async {
    try {
      // Gunakan method Firestore untuk menghapus
      final success =
          await _commentService.saveArticle(article.url, false);
      print('Remove result: $success');
      if (mounted && success) {
        setState(() {
          _savedArticles.removeWhere((a) => a.url == article.url);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikel dihapus dari simpanan'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus artikel: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC), // Pastel cream background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFFF8F4EC),
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Artikel Tersimpan',
                  style: TextStyle(
                    color: const Color(0xFF4F4F4F),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
              ),
              actions: [
                IconButton(
                  onPressed: () => _loadSavedArticles(refresh: true),
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: userId == null
                  ? const Center(child: Text('Anda belum login'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('savedArticles')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bookmark_border_rounded,
                                    size: 80,
                                    color: const Color(0xFFBDBDBD),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada artikel tersimpan',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4F4F4F),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Simpan artikel yang menarik untuk dibaca nanti',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final articles = snapshot.data!.docs
                            .map((doc) => Article.fromJson(
                                doc.data() as Map<String, dynamic>))
                            .toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return _buildArticleItem(article, isDark);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleItem(Article article, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailScreen(article: article),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFBDBDBD).withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                    ),
                    child: article.urlToImage != null &&
                            article.urlToImage!.isNotEmpty
                        ? Image.network(
                            article.urlToImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(
                              Icons.image_not_supported_rounded,
                              color: const Color(0xFFBDBDBD),
                              size: 32,
                            ),
                          )
                        : Icon(
                            Icons.article_rounded,
                            color: const Color(0xFFBDBDBD),
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7280).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.sourceName,
                          style: TextStyle(
                            color: const Color(0xFF4B5563),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF4F4F4F),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: const Color(0xFFBDBDBD),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yyyy').format(article.publishedAt),
                            style: TextStyle(
                              color: const Color(0xFFBDBDBD),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Remove button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => _showRemoveDialog(article),
                    icon: Icon(
                      Icons.bookmark_remove_rounded,
                      color: const Color(0xFF6B7280),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(Article article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Hapus dari Simpanan',
          style: TextStyle(
            color: const Color(0xFF4F4F4F),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel ini dari simpanan?',
          style: TextStyle(
            color: const Color(0xFF4F4F4F),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: const Color(0xFFBDBDBD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromSaved(article);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
