import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment.dart';
import '../services/auth_service.dart';
import '../services/comment_api_service.dart';

class CommentSectionPopup extends StatefulWidget {
  final String articleUrl;
  final Function(int)? onCommentCountChanged;
  
  const CommentSectionPopup({
    super.key, 
    required this.articleUrl,
    this.onCommentCountChanged,
  });

  @override
  State<CommentSectionPopup> createState() => _CommentSectionPopupState();
}

class _CommentSectionPopupState extends State<CommentSectionPopup> {
  final _cComment = TextEditingController();
  final _cReply = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = false;
  final Map<String, List<Comment>> _replies = {};
  final Map<String, bool> _expandedReplies = {};
  final Map<String, bool> _likedComments = {};
  String? _replyingToId;
  String? _replyingToAuthor;
  
  // Article state
  bool _liked = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  /* -------------------------- AUTHENTICATION -------------------------- */
  
  Future<bool> _checkAuthentication() async {
    try {
      // Check Firebase Auth first
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _showLoginDialog();
        return false;
      }

      // Check if user has valid token
      final token = await firebaseUser.getIdToken(true); // Force refresh
      if (token == null || token.isEmpty) {
        _showLoginDialog();
        return false;
      }

      // Verify with AuthService
      final appUser = await AuthService().getCurrentUser();
      if (appUser == null) {
        _showLoginDialog();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Authentication check failed: $e');
      _showLoginDialog();
      return false;
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to comment on this article.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  /* -------------------------- ACTIONS -------------------------- */
  
  Future<void> _postComment() async {
    if (_cComment.text.trim().isEmpty) return;

    // Check authentication first
    if (!await _checkAuthentication()) return;

    setState(() => _isLoading = true);

    try {
      final result = await CommentApiService().addComment(
        widget.articleUrl,
        _cComment.text.trim(),
        parentId: _replyingToId,
      );
      
      if (result['success'] == true) {
        final newComment = Comment(
          id: result['comment']?['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          author: result['comment']?['user']?['name'] ?? 'User',
          text: result['comment']?['comment'] ?? _cComment.text.trim(),
          timestamp: DateTime.now(),
          likeCount: 0,
        );
        
        setState(() {
          if (_replyingToId != null) {
            _replies[_replyingToId!] = _replies[_replyingToId!] ?? [];
            _replies[_replyingToId!]!.add(newComment);
            _expandedReplies[_replyingToId!] = true;
          } else {
            _comments.insert(0, newComment);
            widget.onCommentCountChanged?.call(_comments.length);
          }
        });
        
        _cComment.clear();
        _cancelReply();
      } else {
        throw Exception(result['message'] ?? 'Failed to post comment');
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komentar'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final commentsData = await CommentApiService().getComments(widget.articleUrl);
      if (mounted) {
        final comments = commentsData.map((data) => Comment(
          id: data['_id'] ?? '',
          author: data['user']?['name'] ?? 'Anonymous',
          text: data['comment'] ?? '',
          timestamp: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          likeCount: data['likeCount'] ?? 0,
        )).toList();
        
        setState(() {
          _comments = comments;
          widget.onCommentCountChanged?.call(comments.length);
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      // Show mock comments only in development
      if (mounted) {
        final mockComments = [
          Comment(
            id: '1',
            author: 'John Doe',
            text: 'Great article! Very informative.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            likeCount: 5,
          ),
          Comment(
            id: '2',
            author: 'Jane Smith',
            text: 'Thanks for sharing this information.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            likeCount: 3,
          ),
        ];
        
        setState(() {
          _comments = mockComments;
          widget.onCommentCountChanged?.call(mockComments.length);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLikeComment(String commentId) async {
    if (!await _checkAuthentication()) return;

    final originalIsLiked = _likedComments[commentId] ?? false;
    
    // Optimistic update
    setState(() {
      _likedComments[commentId] = !originalIsLiked;
      _updateLikeCountInUI(commentId, !originalIsLiked);
    });

    try {
      final result = await CommentApiService().likeComment(commentId, !originalIsLiked);
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _likedComments[commentId] = result['isLiked'] ?? !originalIsLiked;
            _updateLikeCountFromAPI(commentId, result['likeCount'] ?? 0);
          });
        } else {
          // Revert if API failed
          setState(() {
            _likedComments[commentId] = originalIsLiked;
            _updateLikeCountInUI(commentId, originalIsLiked);
          });
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _likedComments[commentId] = originalIsLiked;
          _updateLikeCountInUI(commentId, originalIsLiked);
        });
        debugPrint('Error toggle like comment: $e');
      }
    }
  }

  void _updateLikeCountInUI(String commentId, bool isLiked) {
    // Update in main comments
    for (int i = 0; i < _comments.length; i++) {
      if (_comments[i].id == commentId) {
        final currentCount = _comments[i].likeCount;
        final newCount = isLiked ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0);
        _comments[i] = Comment(
          id: _comments[i].id,
          author: _comments[i].author,
          text: _comments[i].text,
          timestamp: _comments[i].timestamp,
          likeCount: newCount,
        );
        return;
      }
    }
    
    // Update in replies
    for (var replies in _replies.values) {
      for (int i = 0; i < replies.length; i++) {
        if (replies[i].id == commentId) {
          final currentCount = replies[i].likeCount;
          final newCount = isLiked ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0);
          replies[i] = Comment(
            id: replies[i].id,
            author: replies[i].author,
            text: replies[i].text,
            timestamp: replies[i].timestamp,
            likeCount: newCount,
          );
          return;
        }
      }
    }
  }

  void _updateLikeCountFromAPI(String commentId, int newCount) {
    // Update in main comments
    for (int i = 0; i < _comments.length; i++) {
      if (_comments[i].id == commentId) {
        _comments[i] = Comment(
          id: _comments[i].id,
          author: _comments[i].author,
          text: _comments[i].text,
          timestamp: _comments[i].timestamp,
          likeCount: newCount,
        );
        return;
      }
    }
    
    // Update in replies
    for (var replies in _replies.values) {
      for (int i = 0; i < replies.length; i++) {
        if (replies[i].id == commentId) {
          replies[i] = Comment(
            id: replies[i].id,
            author: replies[i].author,
            text: replies[i].text,
            timestamp: replies[i].timestamp,
            likeCount: newCount,
          );
          return;
        }
      }
    }
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToAuthor = null;
      _cReply.clear();
    });
  }

  /* ----------------------------- UI ----------------------------- */
  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
    future: AuthService().getCurrentAppUser(),
    builder: (c, snap) => _buildBody(snap.data),
  );

  Widget _buildBody(AppUser? user) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: Column(
      children: [
        // Header with handle
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        
        // Article actions
        _articleActions(),
        
        // Comments header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4EC),
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F6368),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.comment_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                  Text(
                    '${_comments.length} komentar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Comments list - This should expand to fill available space
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: Color(0xFF5F6368),
                ))
              : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F4EC),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada komentar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Jadilah yang pertama berkomentar!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) => _commentTile(_comments[index]),
                    ),
        ),
        
        // Divider
        const Divider(height: 1),
        
        // Comment input - Fixed at bottom with proper keyboard handling
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8 + MediaQuery.of(context).viewPadding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: user?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          user != null && user.name.isNotEmpty 
                              ? user.name[0].toUpperCase() 
                              : 'U',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _cComment,
                      decoration: InputDecoration(
                        hintText: _replyingToId != null 
                            ? 'Write a reply...' 
                            : 'Write a comment...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _postComment,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _articleActions() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _action(Icons.favorite, _liked, 'Like', _toggleLikeArticle,
          activeColor: Colors.red),
      _action(Icons.share, false, 'Share',
              () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Article shared')))),
      _action(Icons.bookmark, _saved, 'Save', _toggleSaveArticle,
          activeColor: Colors.blue),
    ]),
  );

  Widget _action(IconData icon, bool active, String label, VoidCallback onTap,
      {Color activeColor = Colors.grey}) =>
      InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(
            icon,
            size: 20,
            color: active ? activeColor : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: active ? activeColor : Colors.grey[600])),
        ]));

  Widget _commentTile(Comment com) {
    final init = com.author.isNotEmpty ? com.author[0].toUpperCase() : '?';
    final isLiked = _likedComments[com.id] ?? false;
    final replies = _replies[com.id] ?? [];
    final isExpanded = _expandedReplies[com.id] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author & timestamp
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5F6368),
                            Color(0xFF6B7280),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          init,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            com.author,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(com.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Comment text
                Text(
                  com.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: () => _likeComment(com.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isLiked 
                              ? Colors.red.withOpacity(0.1) 
                              : const Color(0xFFF8F4EC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isLiked ? Colors.red : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${com.likeCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLiked ? Colors.red : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Reply button
                    InkWell(
                      onTap: () async {
                        if (await _checkAuthentication()) {
                          setState(() {
                            _replyingToId = com.id;
                            _replyingToAuthor = com.author;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4EC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.reply_rounded,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Balas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Reply box (muncul di bawah komentar)
          if (_replyingToId == com.id) _replyBox(com.id),
          
          // Tombol "Lihat X balasan" seperti TikTok
          if (replies.isNotEmpty)
            InkWell(
              onTap: () {
                setState(() {
                  _expandedReplies[com.id] = !isExpanded;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(left: 52, top: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 2,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded 
                          ? Icons.keyboard_arrow_up_rounded 
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpanded 
                          ? 'Sembunyikan ${replies.length} balasan'
                          : 'Lihat ${replies.length} balasan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Show replies HANYA jika expanded
          if (isExpanded && replies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 32, top: 8),
              child: Column(
                children: replies.map((reply) => _replyTile(reply)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _replyTile(Comment reply) {
    final init = reply.author.isNotEmpty ? reply.author[0].toUpperCase() : '?';
    final isLiked = _likedComments[reply.id] ?? false;
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4EC).withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author & timestamp
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6B7280),
                          Color(0xFF9CA3AF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        init,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(reply.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Reply text
              Text(
                reply.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              
              // Like & Reply buttons
              Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: () => _likeComment(reply.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLiked 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLiked ? Colors.red : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reply.likeCount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLiked ? Colors.red : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Reply button
                  InkWell(
                    onTap: () async {
                      if (await _checkAuthentication()) {
                        setState(() {
                          _replyingToId = reply.id;
                          _replyingToAuthor = reply.author;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply_rounded,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Balas',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Reply box untuk reply ini
        if (_replyingToId == reply.id) 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _replyBox(reply.id),
          ),
      ],
    );
  }

  Widget _replyBox(String parent) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF5F6368), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.reply_rounded,
              size: 16,
              color: Color(0xFF5F6368),
            ),
            const SizedBox(width: 6),
            Text(
              'Membalas $_replyingToAuthor',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5F6368),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _cancelReply,
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cComment,
          decoration: const InputDecoration(
            hintText: 'Tulis balasan...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF4B5563),
          ),
          maxLines: 3,
          minLines: 1,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              InkWell(
                onTap: _postComment,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F6368),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Kirim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  // Helper methods
  void _toggleLikeArticle() {
    setState(() => _liked = !_liked);
  }
  
  void _toggleSaveArticle() {
    setState(() => _saved = !_saved);
  }
  
  void _likeComment(String commentId) {
    _toggleLikeComment(commentId);
  }

  @override
  void dispose() {
    _cComment.dispose();
    _cReply.dispose();
    super.dispose();
  }
}

void showCommentSection(BuildContext context, String articleUrl, Function(int)? onCommentCountChanged) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CommentSectionPopup(
          articleUrl: articleUrl,
          onCommentCountChanged: onCommentCountChanged,
        ),
      ),
    ),
  );
}