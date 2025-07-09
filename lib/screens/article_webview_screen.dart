import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'dart:async';
import '../models/article.dart';
import '../widgets/comment_section_widget.dart';
import '../services/comment_api_service.dart';
import '../services/auth_service.dart'; // Add this import

class ArticleWebviewScreen extends StatefulWidget {
  final Article article;

  const ArticleWebviewScreen({super.key, required this.article});

  @override
  State<ArticleWebviewScreen> createState() => _ArticleWebviewScreenState();
}

class _ArticleWebviewScreenState extends State<ArticleWebviewScreen> {
  late final WebViewController _controller;
  int _loadingPercentage = 0;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  int _commentCount = 0;
  final AuthService _authService = AuthService(); // Add auth service instance

  @override
  void initState() {
    super.initState();
    _loadArticleStats();

    // Initialize WebView controller with optimized settings
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loadingPercentage = 0);
          },
          onProgress: (p) {
            if (mounted) setState(() => _loadingPercentage = p);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loadingPercentage = 100);
          },
          onWebResourceError: (err) => debugPrint('WebView error: ${err.description}'),
        ),
      )
      // Add user agent and other optimizations
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..loadRequest(Uri.parse(widget.article.url));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadArticleStats() async {
    try {
      final stats = await CommentApiService().getArticleStats(widget.article.url);
      if (mounted) {
        setState(() {
          _likeCount = stats['likeCount'] ?? 0;
          _commentCount = stats['commentCount'] ?? 0;
          _isLiked = stats['isLiked'] ?? false;
          _isSaved = stats['isSaved'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load article stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data artikel: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _toggleLike() async {
    if (!mounted) return;
    
    final originalIsLiked = _isLiked;
    final originalLikeCount = _likeCount;
    
    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    try {
      final result = await CommentApiService().likeArticle(widget.article.url, _isLiked);
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _likeCount = result['likeCount'] ?? _likeCount;
            _isLiked = result['isLiked'] ?? _isLiked;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLiked ? 'Artikel disukai ❤️' : 'Like dihapus'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Revert if API call failed
          setState(() {
            _isLiked = originalIsLiked;
            _likeCount = originalLikeCount;
          });
          
          final message = result['message'] ?? 'Gagal mengupdate like';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
          
          // If authentication failed, redirect to login
          if (message.contains('Authentication failed') || message.contains('login again')) {
            _authService.handleTokenExpiration(context); // Fix: Use instance method
          }
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _isLiked = originalIsLiked;
          _likeCount = originalLikeCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSave() async {
    if (!mounted) return;
    
    final originalIsSaved = _isSaved;
    
    // Optimistic update
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      final success = await CommentApiService().saveArticle(widget.article.url, _isSaved);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isSaved ? 'Artikel disimpan 📚' : 'Artikel dihapus dari simpanan'),
              backgroundColor: _isSaved ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Revert on failure
          setState(() {
            _isSaved = originalIsSaved;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengupdate status simpan. Silakan login ulang.'),
              backgroundColor: Colors.red,
            ),
          );
          
          // Redirect to login if authentication failed
          _authService.handleTokenExpiration(context); // Fix: Use instance method
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isSaved = originalIsSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareArticle() async {
    try {
      await Share.share(
        '${widget.article.title}\n\n${widget.article.url}',
        subject: widget.article.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan artikel: $e')),
        );
      }
    }
  }

  // Enhanced comment popup with reply system
  void _showEnhancedCommentPopup() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => EnhancedCommentSectionPopup(
          articleUrl: widget.article.url,
          onCommentCountChanged: (count) {
            if (mounted) {
              setState(() {
                _commentCount = count;
              });
            }
          },
        ),
      ),
    );
    
    // Refresh stats when comment popup closes
    if (result == true && mounted) {
      _loadArticleStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900]!.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        title: Text(
          widget.article.sourceName, 
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.open_in_browser,
              color: isDark ? Colors.white : Colors.black87,
              size: 22,
            ),
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView - Full Article Content
          Positioned.fill(
            bottom: 80,
            child: WebViewWidget(controller: _controller),
          ),
          
          // Loading indicator
          if (_loadingPercentage < 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: _loadingPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.blue[400]! : Colors.blue[600]!,
                  ),
                ),
              ),
            ),
          
          // Fixed Floating Navigation with Better Icon Alignment
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 56, // Reduced height to prevent overflow
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                          ? [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.grey[900]!.withValues(alpha: 0.4),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.6),
                              Colors.grey[50]!.withValues(alpha: 0.7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      width: 1,
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFixedFloatingIcon(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red[500]! : (isDark ? Colors.white70 : Colors.grey[700]!),
                        onTap: _toggleLike,
                        count: _likeCount,
                        isActive: _isLiked,
                      ),
                      
                      _buildFixedFloatingIcon(
                        icon: Icons.chat_bubble_outline,
                        color: isDark ? Colors.white70 : Colors.grey[700]!,
                        onTap: _showEnhancedCommentPopup,
                        count: _commentCount,
                        isActive: false,
                      ),
                      
                      _buildFixedFloatingIcon(
                        icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved ? Colors.blue[500]! : (isDark ? Colors.white70 : Colors.grey[700]!),
                        onTap: _toggleSave,
                        isActive: _isSaved,
                      ),
                      
                      _buildFixedFloatingIcon(
                        icon: Icons.share_outlined,
                        color: isDark ? Colors.white70 : Colors.grey[700]!,
                        onTap: _shareArticle,
                        isActive: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fixed icon widget with proper alignment and no overflow
  Widget _buildFixedFloatingIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? count,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Container(
            height: 56, // Fixed height matching parent
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(8), // Reduced padding
                  decoration: BoxDecoration(
                    color: isActive 
                        ? color.withValues(alpha: 0.15) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isActive ? Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ) : null,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20, // Smaller icon
                  ),
                ),
                
                // Counter badge - positioned to not cause overflow
                if (count != null && count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14), // Smaller badge
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isDark ? Colors.black : Colors.white, 
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            fontSize: 7, // Smaller font
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
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
}

// Keep the old class name for backward compatibility
class ArticleDetailScreen extends ArticleWebviewScreen {
  const ArticleDetailScreen({super.key, required super.article});
}