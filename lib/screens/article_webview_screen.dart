import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article.dart';
import '../widgets/comment_section_widget.dart'; // Import widget baru
import '../services/article_interaction_service.dart';
import 'login_screen.dart';

class ArticleWebviewScreen extends StatefulWidget {
  final Article article;

  const ArticleWebviewScreen({super.key, required this.article});

  @override
  State<ArticleWebviewScreen> createState() => _ArticleWebviewScreenState();
}

class _ArticleWebviewScreenState extends State<ArticleWebviewScreen> {
  late final WebViewController _controller;
  final ArticleInteractionService _interactionService = ArticleInteractionService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _loadingPercentage = 0;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadArticleStats();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loadingPercentage = 0),
          onProgress: (p) => setState(() => _loadingPercentage = p),
          onPageFinished: (_) => setState(() => _loadingPercentage = 100),
          onWebResourceError: (err) => debugPrint('WebView error: ${err.description}'),
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  Future<void> _loadArticleStats() async {
    try {
      final stats = await _interactionService.getArticleStats(widget.article.url, _currentUser?.uid);
      if (mounted) {
        setState(() {
          _likeCount = stats['likeCount'];
          _commentCount = stats['commentCount'];
          _isLiked = stats['isLiked'];
          _isSaved = stats['isSaved'];
        });
      }
    } catch (e) {
      debugPrint('Failed to load article stats: $e');
    }
  }

  void _toggleLike() async {
    if (_currentUser == null) {
      _showLoginRequired();
      return;
    }

    final originalIsLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await _interactionService.toggleLike(widget.article.url, _currentUser!.uid, originalIsLiked);
    } catch (e) {
      setState(() {
        _isLiked = originalIsLiked;
        _likeCount += originalIsLiked ? 1 : -1;
      });
      _showErrorSnackbar('Gagal memperbarui status suka.');
    }
  }

  void _toggleSave() async {
    if (_currentUser == null) {
      _showLoginRequired();
      return;
    }
    
    final originalIsSaved = _isSaved;
    setState(() => _isSaved = !_isSaved);

    try {
      await _interactionService.toggleBookmark(_currentUser!.uid, widget.article, originalIsSaved);
    } catch (e) {
      setState(() => _isSaved = originalIsSaved);
      _showErrorSnackbar('Gagal menyimpan artikel.');
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Anda harus login untuk melakukan aksi ini.'),
        action: SnackBarAction(
          label: 'LOGIN',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareArticle() async {
    await Share.share(
      '${widget.article.title}\n\n${widget.article.url}',
      subject: widget.article.title,
    );
  }

  // --- FUNGSI KOMENTAR (DIPERBARUI) ---
  void _showEnhancedCommentPopup() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return EnhancedCommentSectionPopup(
              articleUrl: widget.article.url,
              onCommentCountChanged: (count) {
                if (mounted) {
                  setState(() {
                    _commentCount = count;
                  });
                }
              },
            );
          },
        );
      },
    );
    _loadArticleStats();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900]!.withOpacity(0.95) : Colors.white.withOpacity(0.95),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        title: Text(
          widget.article.sourceName, 
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loadingPercentage < 100)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(value: _loadingPercentage / 100),
            ),
        ],
      ),
      // --- BOTTOM NAVIGATION BAR (DIPERBARUI) ---
      bottomNavigationBar: BottomAppBar(
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomAction(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'Suka',
                count: _likeCount,
                color: _isLiked ? Colors.red : null,
                onTap: _toggleLike,
              ),
              _buildBottomAction(
                icon: Icons.chat_bubble_outline,
                label: 'Komentar',
                count: _commentCount,
                onTap: _showEnhancedCommentPopup,
              ),
              _buildBottomAction(
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                label: 'Simpan',
                color: _isSaved ? Colors.blue : null,
                onTap: _toggleSave,
              ),
              _buildBottomAction(
                icon: Icons.share_outlined,
                label: 'Bagikan',
                onTap: _shareArticle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? count,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: color)),
                if (count != null && count > 0)
                  Text(' ($count)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleDetailScreen extends ArticleWebviewScreen {
  const ArticleDetailScreen({super.key, required super.article});
}