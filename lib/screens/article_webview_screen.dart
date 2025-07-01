import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Import provider
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart'; // <-- Import BookmarkService
import '../widgets/comment_section_popup.dart';

class ArticleWebviewScreen extends StatefulWidget {
  final Article article;

  const ArticleWebviewScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  State<ArticleWebviewScreen> createState() => _ArticleWebviewScreenState();
}

class _ArticleWebviewScreenState extends State<ArticleWebviewScreen> {
  late final WebViewController _controller;
  double _loadingProgress = 0;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = (widget.article.title.length % 30) + 5;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _loadingProgress = progress / 100);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  void _showCommentsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return CommentSectionPopup(articleUrl: widget.article.url);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendapatkan akses ke BookmarkService
    return Consumer<BookmarkService>(
      builder: (context, bookmarkService, child) {
        final isBookmarked = bookmarkService.isBookmarked(widget.article);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.article.sourceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            automaticallyImplyLeading: false,
            bottom: _loadingProgress < 1.0
                ? PreferredSize(
              preferredSize: const Size.fromHeight(3.0),
              child: LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade300),
              ),
            )
                : null,
            // --- REVISI: TOMBOL-TOMBOL AKSI DI APPBAR ---
            actions: [
              // Tombol Like
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey[700],
                ),
                onPressed: () {
                  setState(() => _isLiked = !_isLiked);
                },
              ),
              // Tombol Bookmark
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.amber[700] : Colors.grey[700],
                ),
                onPressed: () {
                  bookmarkService.toggleBookmark(widget.article);
                },
              ),
              // Tombol Share
              IconButton(
                icon: const Icon(Icons.share_outlined),
                color: Colors.grey[700],
                onPressed: () => Share.share('Baca berita ini: ${widget.article.url}'),
              ),
            ],
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildFloatingBottomBar(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk panel bawah
  Widget _buildFloatingBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.comment_outlined),
            label: const Text('Komentar'),
            onPressed: _showCommentsPopup,
            style: TextButton.styleFrom(foregroundColor: Colors.grey[800]),
          ),
          // Placeholder agar seimbang
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}