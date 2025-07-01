// GANTI SEMUA IMPORT ANDA DENGAN BLOK INI

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // <-- SUDAH DIPERBAIKI
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';

import '../models/article.dart';
import '../models/comment.dart';
import '../services/comment_firebase_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final CommentFirebaseService _commentService = CommentFirebaseService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showFullContent = false;
  bool _isLoadingFullContent = false;
  String? _fullArticleHtmlContent;
  String? _errorMessage;

  List<Comment> _comments = [];
  bool _isLoadingComments = true;

  bool _isBookmarked = false;
  bool _isLiked = false;
  int _likeCount = 0;
  double _readingProgress = 0.0;
  double _fontSize = 16.0;
  int _estimatedReadTime = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = (widget.article.title.length % 50) + 10;
    _calculateReadingTime();
    _scrollController.addListener(_updateReadingProgress);
    _loadComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _calculateReadingTime() {
    final content = _fullArticleHtmlContent ?? widget.article.content ?? '';
    final wordCount = content.replaceAll(RegExp(r'<[^>]*>'), ' ').split(RegExp(r'\s+')).length;
    setState(() {
      _estimatedReadTime = (wordCount / 200).ceil();
    });
  }

  void _updateReadingProgress() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      final progress = (_scrollController.offset / _scrollController.position.maxScrollExtent).clamp(0.0, 1.0);
      setState(() => _readingProgress = progress);
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _commentService.getComments(widget.article.url);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      articleIdentifier: widget.article.url,
      author: 'Anonymous User',
      text: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );
    try {
      await _commentService.addComment(comment);
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan komentar: $e')),
      );
    }
  }

  Future<void> _loadFullArticleContent() async {
    setState(() {
      _isLoadingFullContent = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(widget.article.url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        String? cleanedHtml = _extractCleanedArticleHtml(document);
        if (cleanedHtml != null && cleanedHtml.isNotEmpty) {
          setState(() {
            _fullArticleHtmlContent = cleanedHtml;
            _showFullContent = true;
          });
          _calculateReadingTime();
        } else {
          _errorMessage = 'Tidak dapat mengambil konten lengkap. Coba buka di web.';
        }
      } else {
        _errorMessage = 'Gagal memuat artikel. Status: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error memuat artikel: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoadingFullContent = false);
      }
    }
  }

  String? _extractCleanedArticleHtml(dom.Document document) {
    const List<String> contentSelectors = [
      'article', '.article-content', '.post-content', '.entry-content', '.content',
      '.article-body', '.story-content', '.read__content', '.detail-content',
    ];
    const List<String> selectorsToRemove = [
      'script', 'style', 'nav', 'header', 'footer', 'aside', '.ads', '.iklan',
      '.social-share', '.related-articles', '.comments', '.sidebar', '.breadcrumb',
      'figure > figcaption' // Hapus caption di dalam gambar
    ];
    for (String selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        for (String toRemove in selectorsToRemove) {
          element.querySelectorAll(toRemove).forEach((el) => el.remove());
        }

        String finalHtml = element.innerHtml;

        // --- TAHAP PEMBERSIHAN EKSTRA ---
        // Hapus teks "Baca Juga" atau "Lihat Juga"
        finalHtml = finalHtml.replaceAll(RegExp(r'<li>\s*Baca Juga:.*?</li>', caseSensitive: false, dotAll: true), '');
        finalHtml = finalHtml.replaceAll(RegExp(r'<p>\s*Baca Juga:.*?</p>', caseSensitive: false, dotAll: true), '');
        // Hapus teks aneh seperti "0:00" dan "News folgen"
        finalHtml = finalHtml.replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), '');
        finalHtml = finalHtml.replaceAll('News folgen', '');

        if (finalHtml.trim().length > 300) {
          return finalHtml;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildArticleHeader(),
                      const SizedBox(height: 24),
                      _buildActionBar(),
                      const Divider(height: 48, thickness: 0.5),
                      _buildArticleBody(),
                      const Divider(height: 48, thickness: 0.5),
                      _buildCommentsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedOpacity(
                opacity: _readingProgress > 0.02 && _readingProgress < 0.98 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: LinearProgressIndicator(
                  value: _readingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
              onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, size: 20, color: Colors.white),
              onPressed: () => Share.share('${widget.article.title}\n\n${widget.article.url}'),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Hero(
          tag: widget.article.url,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.article.urlToImage != null && widget.article.urlToImage!.isNotEmpty)
                Image.network(
                  widget.article.urlToImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                )
              else
                _imagePlaceholder(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    stops: const [0.0, 0.5],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 50));

  Widget _buildArticleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.article.sourceName.isNotEmpty) ...[
          Text(
            widget.article.sourceName,
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          widget.article.title,
          style: const TextStyle(
            fontFamily: 'Merriweather', // Contoh font serif yang elegan
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.article.author ?? 'Tim Redaksi',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$_estimatedReadTime min baca', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: '$_likeCount',
            color: _isLiked ? Colors.red : Colors.grey.shade700,
            onTap: () => setState(() {
              _isLiked = !_isLiked;
              _likeCount += _isLiked ? 1 : -1;
            }),
          ),
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: '${_comments.length}',
            color: Colors.grey.shade700,
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.open_in_new,
            label: 'Web',
            color: Colors.grey.shade700,
            onTap: () async => launchUrl(Uri.parse(widget.article.url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleBody() {
    if (_showFullContent) {
      if (_fullArticleHtmlContent != null) {
        return Column(
          children: [
            _buildFontControl(),
            const SizedBox(height: 16),
            // --- STYLING HTML YANG LEBIH BAIK ---
            Html(
              data: _fullArticleHtmlContent,
              style: {
                // Style untuk semua tag
                "body": Style(
                  fontSize: FontSize(_fontSize),
                  lineHeight: const LineHeight(1.7),
                  color: const Color(0xFF333333),
                  fontFamily: 'NotoSerif', // Font serif lain yang bagus
                ),
                // Style khusus paragraf
                "p": Style(
                  margin: Margins.only(bottom: 16),
                  textAlign: TextAlign.justify,
                ),
                // Style untuk semua level heading
                "h1, h2, h3, h4, h5, h6": Style(
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24, bottom: 8),
                  fontFamily: 'Merriweather',
                ),
                // Style untuk gambar
                "img": Style(
                  width: Width.auto(),
                  margin: Margins.symmetric(vertical: 16),
                  // Tambahkan border radius pada gambar
                  // Ini memerlukan custom render, tapi bisa kita coba
                ),
                // Style untuk link
                "a": Style(
                  color: Colors.deepPurple,
                  textDecoration: TextDecoration.none,
                  fontWeight: FontWeight.bold,
                ),
                // Style untuk blockquote
                "blockquote": Style(
                  backgroundColor: Colors.grey.shade100,
                  padding: HtmlPaddings.all(16),
                  border: Border(left: BorderSide(color: Colors.deepPurple.shade200, width: 4)),
                  fontStyle: FontStyle.italic,
                ),
                // Style untuk list
                "ul, ol": Style(
                    padding: HtmlPaddings.only(left: 24)
                ),
                "li": Style(
                  lineHeight: const LineHeight(1.5),
                  padding: HtmlPaddings.only(bottom: 8),
                )
              },
              onLinkTap: (url, _, __) {
                if (url != null) launchUrl(Uri.parse(url));
              },
            ),
          ],
        );
      } else if (_errorMessage != null) {
        return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
      } else {
        return const Center(child: Text("Konten tidak dapat ditampilkan."));
      }
    }

    // Tampilan awal (ringkasan & tombol Baca Selengkapnya)
    return Column(
      children: [
        Text(
          widget.article.content ?? 'Ringkasan tidak tersedia. Tekan tombol di bawah untuk membaca seluruh artikel.',
          style: TextStyle(fontSize: _fontSize, height: 1.6, color: Colors.grey[800]),
          maxLines: 8,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 24),
        if (_isLoadingFullContent)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton.icon(
            onPressed: _loadFullArticleContent,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Baca Seluruh Artikel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
      ],
    );
  }

  Widget _buildFontControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
          ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.text_fields_outlined),
            color: Colors.grey.shade600,
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(12.0, 24.0)),
          ),
          Text(_fontSize.toInt().toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(12.0, 24.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Komentar (${_comments.length})', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Bagikan pendapat Anda...',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _addComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Kirim'),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoadingComments)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else if (_comments.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Jadilah yang pertama berkomentar!')))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(backgroundColor: Colors.deepPurple.shade50, child: Text(comment.author[0], style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(comment.text, style: TextStyle(color: Colors.grey.shade800, height: 1.5)),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(comment.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}