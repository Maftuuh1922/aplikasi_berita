import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/article_interaction_service.dart';
import '../services/user_profile_service.dart';
import '../screens/login_screen.dart';

// WIDGET UTAMA UNTUK MENAMPILKAN POPUP KOMENTAR
class EnhancedCommentSectionPopup extends StatefulWidget {
  final String articleUrl;
  final Function(int) onCommentCountChanged;

  const EnhancedCommentSectionPopup({
    Key? key,
    required this.articleUrl,
    required this.onCommentCountChanged,
  }) : super(key: key);

  @override
  _EnhancedCommentSectionPopupState createState() =>
      _EnhancedCommentSectionPopupState();
}

class _EnhancedCommentSectionPopupState extends State<EnhancedCommentSectionPopup> {
  final TextEditingController _commentController = TextEditingController();
  final ArticleInteractionService _interactionService = ArticleInteractionService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  bool _isPosting = false;
  String? _replyToCommentId;
  String? _replyToUserId;
  String _replyToUsername = '';
  String? _rootCommentId;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (_currentUser == null) {
      _showLoginRequired();
      return;
    }

    setState(() => _isPosting = true);

    // Simpan data reply sebelum clear controller
    final String? replyToId = _replyToCommentId;
    final String? replyToUserId = _replyToUserId;
    final String replyToUsername = _replyToUsername;
    final String? rootId = _rootCommentId;

    try {
      await _interactionService.addComment(
        widget.articleUrl,
        _currentUser!.uid,
        text,
        parentId: replyToId,
        rootId: rootId,
        replyToUserId: replyToUserId,
        replyToUsername: replyToUsername,
      );

      // Clear setelah berhasil
      _commentController.clear();
      _clearReplyState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(replyToId != null ? 'Balasan berhasil dikirim!' : 'Komentar berhasil dikirim!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Restore text dan state jika gagal
        _commentController.text = text;
        setState(() {
          _replyToCommentId = replyToId;
          _replyToUserId = replyToUserId;
          _replyToUsername = replyToUsername;
          _rootCommentId = rootId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komentar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _setReplyTo(String commentId, String userId, String username, {String? rootId}) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserId = userId;
      _replyToUsername = username;
      _rootCommentId = rootId ?? commentId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _clearReplyState() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserId = null;
      _replyToUsername = '';
      _rootCommentId = null;
    });
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Anda harus login untuk berinteraksi.'),
        action: SnackBarAction(
          label: 'LOGIN',
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ),
    );
  }

  void _onLikeComment(String articleUrl, String commentId, String userId) async {
    if (_currentUser == null) {
      _showLoginRequired();
      return;
    }

    try {
      await _interactionService.toggleCommentLike(articleUrl, commentId, userId);
      debugPrint('Berhasil like/unlike komentar');
    } catch (e) {
      debugPrint('Gagal like komentar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal like komentar: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text('Komentar', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  StreamBuilder<int>(
                    stream: _interactionService.getCommentCount(widget.articleUrl),
                    builder: (context, snapshot) {
                      final totalComments = snapshot.data ?? 0;
                      
                      // Update comment count callback
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          widget.onCommentCountChanged(totalComments);
                        }
                      });
                      
                      return Text(
                        '($totalComments)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Comments list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _interactionService.getParentComments(widget.articleUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 50, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.comment_outlined, size: 50, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Jadilah yang pertama berkomentar!'),
                        ],
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentDoc = comments[index];
                      final commentData = commentDoc.data() as Map<String, dynamic>;
                      
                      return InstagramCommentTile(
                        key: ValueKey(commentDoc.id),
                        articleUrl: widget.articleUrl,
                        commentId: commentDoc.id,
                        data: commentData,
                        onReply: _setReplyTo,
                        isRootComment: true,
                        currentUserId: _currentUser?.uid,
                        onLike: _onLikeComment,
                      );
                    },
                  );
                },
              ),
            ),
            
            const Divider(height: 1),
            _buildCommentInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reply indicator
          if (_replyToCommentId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Membalas @$_replyToUsername',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearReplyState,
                    child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
          // Input field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: _replyToCommentId == null
                          ? 'Tulis komentar...'
                          : 'Balas @$_replyToUsername...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                    onSubmitted: (_) => _postComment(),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: 1,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isPosting ? null : _postComment,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPosting ? Colors.grey[400] : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET KOMENTAR DENGAN DESAIN INSTAGRAM-LIKE
class InstagramCommentTile extends StatefulWidget {
  final String articleUrl;
  final String commentId;
  final Map<String, dynamic> data;
  final Function(String, String, String, {String? rootId})? onReply;
  final bool isRootComment;
  final String? currentUserId;
  final Function(String, String, String)? onLike;

  const InstagramCommentTile({
    Key? key,
    required this.articleUrl,
    required this.commentId,
    required this.data,
    this.onReply,
    this.isRootComment = false,
    this.currentUserId,
    this.onLike,
  }) : super(key: key);

  @override
  _InstagramCommentTileState createState() => _InstagramCommentTileState();
}

class _InstagramCommentTileState extends State<InstagramCommentTile> {
  final UserProfileService _userProfileService = UserProfileService();
  final ArticleInteractionService _interactionService = ArticleInteractionService();
  
  bool _showReplies = false;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    try {
      final userProfile = await _userProfileService.getUserProfile(widget.data['userId']);
      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _toggleLike() {
    if (widget.currentUserId == null) return;
    widget.onLike?.call(
      widget.articleUrl,
      widget.commentId,
      widget.currentUserId!,
    );
  }

  String get _displayName {
    if (_userProfile != null) {
      return _userProfile!['displayName'] ?? 'Pengguna';
    }
    return 'Pengguna';
  }

  String? get _photoUrl {
    if (_userProfile != null) {
      return _userProfile!['photoURL'];
    }
    return null;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: _photoUrl == null || _photoUrl!.isEmpty
                    ? Text(
                        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment text
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          TextSpan(
                            text: '$_displayName ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: widget.data['comment'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Action buttons
                    Row(
                      children: [
                        // Time
                        Text(
                          _formatTimestamp(widget.data['timestamp']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 20),
                        
                        // Like button
                        StreamBuilder<bool>(
                          stream: widget.currentUserId != null
                              ? _interactionService.isCommentLikedByUser(
                                  widget.articleUrl,
                                  widget.commentId,
                                  widget.currentUserId!,
                                )
                              : Stream.value(false),
                          builder: (context, snapshot) {
                            final isLiked = snapshot.data ?? false;
                            final likeCount = widget.data['likes'] ?? 0;
                            
                            return GestureDetector(
                              onTap: _toggleLike,
                              child: Row(
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: isLiked ? Colors.red : Colors.grey[600],
                                  ),
                                  if (likeCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      likeCount.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        
                        // Reply button
                        if (widget.isRootComment && widget.onReply != null)
                          GestureDetector(
                            onTap: () {
                              widget.onReply!(
                                widget.commentId,
                                widget.data['userId'],
                                _displayName,
                                rootId: widget.data['rootId'] ?? widget.commentId,
                              );
                            },
                            child: Text(
                              'Balas',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Show replies button
                    if (widget.isRootComment && (widget.data['replyCount'] ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showReplies = !_showReplies;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 1,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showReplies
                                    ? 'Sembunyikan balasan'
                                    : 'Lihat ${widget.data['replyCount']} balasan',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showReplies ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Replies section
          if (_showReplies && widget.isRootComment)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: _interactionService.getReplies(widget.articleUrl, widget.data['rootId'] ?? widget.commentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final replies = snapshot.data!.docs;

                  return Column(
                    children: replies.map((replyDoc) {
                      final replyData = replyDoc.data() as Map<String, dynamic>;
                      return InstagramCommentTile(
                        key: ValueKey(replyDoc.id),
                        articleUrl: widget.articleUrl,
                        commentId: replyDoc.id,
                        data: replyData,
                        onReply: widget.onReply,
                        isRootComment: false,
                        currentUserId: widget.currentUserId,
                        onLike: widget.onLike,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}