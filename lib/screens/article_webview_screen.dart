import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';
import '../services/bookmark_service.dart';
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
  bool _pageHasError = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 0;
                _pageHasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 1.0;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Tangani error, misalnya jika halaman tidak bisa di-load di dalam iframe
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            setState(() {
              _pageHasError = true;
            });
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

  Future<void> _openInBrowser() async {
    final url = Uri.parse(widget.article.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Tidak bisa membuka link: ${widget.article.url}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.sourceName),
        actions: [
          // Tombol Bookmark
          Consumer<BookmarkService>(
            builder: (context, bookmarkService, child) {
              final isBookmarked = bookmarkService.isBookmarked(widget.article);
              return IconButton(
                icon:
                    Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () {
                  bookmarkService.toggleBookmark(widget.article);
                },
              );
            },
          ),
          // Tombol Share
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () =>
                Share.share('Baca berita ini: ${widget.article.url}'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          if (_loadingProgress < 1.0)
            LinearProgressIndicator(value: _loadingProgress),
          Expanded(
            // Gunakan Stack untuk menumpuk WebView dan pesan error jika ada
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                // Tampilkan pesan error jika halaman gagal dimuat (misalnya karena X-Frame-Options)
                if (_pageHasError)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 50),
                          const SizedBox(height: 16),
                          const Text(
                            'Halaman ini tidak bisa ditampilkan di dalam aplikasi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openInBrowser,
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Buka di Browser'),
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Tombol komentar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton.icon(
          icon: const Icon(Icons.comment_outlined),
          label: const Text('Lihat atau Tambah Komentar'),
          onPressed: _showCommentsPopup,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
