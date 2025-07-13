import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../services/comment_api_service.dart';
import '../models/article.dart';
import 'article_webview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      if (userId == null) return; // handle jika belum login

      final articles = await _commentService.getSavedArticles(
        userId: userId,
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _savedArticles = articles.map((data) => Article.fromJson(data)).toList();
          } else {
            _savedArticles.addAll(articles.map((data) => Article.fromJson(data)).toList());
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
      final success = await _commentService.saveArticle(article.url, false);
      
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

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.grey[900]!.withValues(alpha: 0.8),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.8),
                                Colors.grey[50]!.withValues(alpha: 0.9),
                              ],
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      title: Text(
                        'Artikel Tersimpan',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => _loadSavedArticles(refresh: true),
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),

            // Content
            if (_isLoading && _savedArticles.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_savedArticles.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada artikel tersimpan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Simpan artikel yang menarik untuk dibaca nanti',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _savedArticles.length) {
                      if (_hasMoreArticles) {
                        _loadMoreArticles();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox(height: 100); // Space for navigation
                    }

                    final article = _savedArticles[index];
                    return _buildArticleItem(article, isDark);
                  },
                  childCount: _savedArticles.length + 1,
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
                builder: (context) => ArticleWebviewScreen(article: article),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]?.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                    child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                        ? Image.network(
                            article.urlToImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(
                              Icons.image_not_supported_rounded,
                              color: isDark ? Colors.grey[600] : Colors.grey[500],
                            ),
                          )
                        : Icon(
                            Icons.article_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.sourceName,
                        style: TextStyle(
                          color: isDark ? Colors.blue[300] : Colors.blue[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('d MMM yyyy').format(article.publishedAt),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Remove button
                IconButton(
                  onPressed: () => _showRemoveDialog(article),
                  icon: Icon(
                    Icons.bookmark_remove,
                    color: Colors.red[400],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Hapus dari Simpanan',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel ini dari simpanan?',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromSaved(article);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[500],
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}