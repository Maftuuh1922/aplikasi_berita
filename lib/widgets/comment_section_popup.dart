import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  /* -------------------------- ACTIONS -------------------------- */
  Future<void> _postComment() async {
    if (_cComment.text.trim().isEmpty) return;
    
    try {
      if (_replyingToId != null) {
        // Post reply using addComment with parentId
        final result = await CommentApiService().addComment(
          widget.articleUrl,
          _cComment.text.trim(),
          parentId: _replyingToId,
        );
        
        if (result['success']) {
          // Create comment from result
          final newComment = Comment(
            id: result['comment']['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            author: result['comment']['user']?['name'] ?? 'User',
            text: result['comment']['comment'] ?? _cComment.text.trim(),
            timestamp: DateTime.now(),
            likeCount: 0,
          );
          
          setState(() {
            _replies[_replyingToId!] = _replies[_replyingToId!] ?? [];
            _replies[_replyingToId!]!.add(newComment);
            _expandedReplies[_replyingToId!] = true;
          });
        }
      } else {
        // Post main comment
        final result = await CommentApiService().addComment(
          widget.articleUrl,
          _cComment.text.trim(),
        );
        
        if (result['success']) {
          // Create comment from result
          final newComment = Comment(
            id: result['comment']['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            author: result['comment']['user']?['name'] ?? 'User',
            text: result['comment']['comment'] ?? _cComment.text.trim(),
            timestamp: DateTime.now(),
            likeCount: 0,
          );
          
          setState(() {
            _comments.insert(0, newComment);
            widget.onCommentCountChanged?.call(_comments.length);
          });
        }
      }
      
      _cComment.clear();
      _cancelReply();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil dikirim'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final commentsData = await CommentApiService().getComments(widget.articleUrl);
      if (mounted) {
        // Convert API response to Comment objects
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
      // Create mock comments for demo when API fails
      final mockComments = [
        Comment(
          id: '1',
          author: 'John Doe',
          text: 'Artikel yang sangat menarik dan informatif!',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          likeCount: 5,
        ),
        Comment(
          id: '2',
          author: 'Jane Smith',
          text: 'Terima kasih atas informasinya, sangat bermanfaat.',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          likeCount: 3,
        ),
      ];
      
      if (mounted) {
        setState(() {
          _comments = mockComments;
          widget.onCommentCountChanged?.call(mockComments.length);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat komentar: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReplies(String commentId) async {
    try {
      // Since the API returns nested replies, we might not need a separate call
      // But if needed, we can implement this later
      debugPrint('Loading replies for comment: $commentId');
    } catch (e) {
      debugPrint('Failed to load replies for $commentId: $e');
    }
  }

  Future<void> _toggleLikeComment(String commentId) async {
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengupdate like komentar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _likedComments[commentId] = originalIsLiked;
          _updateLikeCountInUI(commentId, originalIsLiked);
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
    future: AuthService().getCurrentUser(),
    builder: (c, snap) => _buildBody(snap.data),
  );

  Widget _buildBody(AppUser? user) => Container(
    padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10)),
        ),
        _articleActions(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('Komentar',
                style: Theme.of(context).textTheme.titleLarge),
          ]),
        ),
        _commentsList(),
        const Divider(height: 1),
        _commentInput(user),
      ],
    ),
  );

  Widget _articleActions() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _action(Icons.favorite, _liked, 'Suka', _toggleLikeArticle,
          activeColor: Colors.red),
      _action(Icons.share, false, 'Bagikan',
              () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Artikel dibagikan')))),
      _action(Icons.bookmark, _saved, 'Simpan', _toggleSaveArticle,
          activeColor: Colors.blue),
    ]),
  );

  Widget _action(IconData icon, bool active, String label, VoidCallback onTap,
      {Color activeColor = Colors.grey}) =>
      InkWell(
          onTap: onTap,
          child: Row(children: [
            Icon(active ? icon : IconData(icon.codePoint,
                fontFamily: icon.fontFamily, fontPackage: icon.fontPackage),
                size: 20, color: active ? activeColor : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: active ? activeColor : Colors.grey[600])),
          ]));

  Widget _commentsList() => Expanded(
    child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _comments.isEmpty
            ? const Center(child: Text('Belum ada komentar'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _comments.length,
                itemBuilder: (c, i) => _commentTile(_comments[i]),
              ),
  );

  Widget _commentTile(Comment com) {
    final init = com.author.isNotEmpty ? com.author[0].toUpperCase() : '?';
    final isLiked = _likedComments[com.id] ?? false;
    final replies = _replies[com.id] ?? [];
    
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(init, style: TextStyle(color: Colors.blue[800])),
        ),
        title: Text(com.author, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(com.text),
          const SizedBox(height: 4),
          Text(DateFormat('dd/MM/yyyy HH:mm').format(com.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(children: [
            InkWell(
              onTap: () => _likeComment(com.id),
              child: Row(children: [
                Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked ? Colors.red : Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${com.likeCount}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isLiked ? Colors.red : Colors.grey[600])),
              ]),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () async {
                final user = await AuthService().getCurrentUser();
                if (user == null) return _needLogin();
                setState(() {
                  _replyingToId = com.id;
                  _replyingToAuthor = com.author;
                });
              },
              child: const Row(children: [
                Icon(Icons.reply, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('Balas', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
            if (replies.isNotEmpty) ...[
              const SizedBox(width: 16),
              Text('${replies.length} balasan',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ])
        ]),
      ),
      if (_replyingToId == com.id) _replyBox(com.id),
      
      // Show replies
      if (replies.isNotEmpty)
        ...replies.map((reply) => Container(
          margin: const EdgeInsets.only(left: 48),
          child: _commentTile(reply),
        )),
    ]);
  }

  Widget _replyBox(String parent) => Container(
    margin: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
        color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Membalas $_replyingToAuthor',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _cComment, // Use main controller for consistency
              decoration: const InputDecoration(
                  hintText: 'Tulis balasan...', border: InputBorder.none),
              maxLines: null,
            ),
          ),
          IconButton(
              icon: const Icon(Icons.send, size: 20),
              onPressed: _postComment, // Use main post method
              color: Theme.of(context).primaryColor),
          IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _cancelReply,
              color: Colors.grey[600]),
        ]),
      ],
    ),
  );

  Widget _commentInput(AppUser? user) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue[100],
        child: user?.photoUrl != null
            ? ClipOval(child: Image.network(user!.photoUrl!, width: 32, height: 32, fit: BoxFit.cover))
            : Text(
                user?.name?.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
              ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: _cComment,
          decoration: InputDecoration(
            hintText: _replyingToId != null ? 'Tulis balasan...' : 'Tulis komentar...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          maxLines: null,
        ),
      ),
      IconButton(
          icon: const Icon(Icons.send),
          onPressed: _postComment,
          color: Theme.of(context).primaryColor)
    ]),
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
  
  void _needLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silakan login terlebih dahulu')),
    );
  }

  @override
  void dispose() {
    _cComment.dispose();
    _cReply.dispose();
    super.dispose();
  }
}