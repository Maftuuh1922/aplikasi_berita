import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/article_interaction_service.dart';
import '../services/user_profile_service.dart';
import '../screens/login_screen.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
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
      setState(() {
        // Jika baru membalas, buka balasan pada parent comment
        if (replyToId != null) {
          // Trigger showReplies pada parent comment (bisa lewat callback atau state management)
          // Atau reload widget agar balasan langsung muncul
        }
      });

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

  // Fungsi untuk menangani terjemahan
  void _translateComment(String text) {
    // Implementasi terjemahan di sini
    // Anda bisa menggunakan Google Translate API atau service lainnya
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terjemahan: $text'), // Placeholder untuk hasil terjemahan
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteConfirmation(String commentId, bool isRootComment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Komentar'),
          content: Text(isRootComment
              ? 'Hapus komentar ini akan menghapus semua balasannya. Yakin?'
              : 'Yakin ingin menghapus komentar ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteComment(commentId, isRootComment);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _deleteComment(String commentId, bool isRootComment) async {
    debugPrint('DEBUG: Proses hapus komentar $commentId, isRootComment: $isRootComment');
    try {
      if (isRootComment) {
        await _interactionService.deleteCommentWithReplies(widget.articleUrl, commentId);
      } else {
        await _interactionService.deleteComment(widget.articleUrl, commentId);
      }
      debugPrint('DEBUG: Komentar $commentId berhasil dihapus');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Memicu rebuild StreamBuilder
        widget.onCommentCountChanged(-1); // Kurangi count manual jika perlu
      }
    } catch (e) {
      debugPrint('ERROR: Gagal menghapus komentar $commentId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Ubah ke warna putih untuk light mode
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Komentar',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StreamBuilder<int>(
                  stream: ArticleInteractionService().getCommentCount(widget.articleUrl),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    print('DEBUG NAVIGASI COMMENT COUNT: $count');
                    return Row(
                      children: [
                        Icon(Icons.comment, size: 20),
                        SizedBox(width: 4),
                        Text('Komentar ($count)'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _interactionService.getParentComments(widget.articleUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
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
                        Text(
                          'Jadilah yang pertama berkomentar!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final comments = snapshot.data!.docs;
                final parentComments = comments.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['level'] == 0;
                }).toList();

                // Update comment count
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onCommentCountChanged(comments.length);
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: parentComments.length,
                  itemBuilder: (context, index) {
                    final commentDoc = parentComments[index];
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
                      onTranslate: _translateComment,
                      onDelete: _showDeleteConfirmation, // <-- PENTING!
                    );
                  },
                );
              },
            ),
          ),

          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Tambahkan padding untuk keyboard
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyToCommentId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Membalas @$_replyToUsername',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearReplyState,
                      child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                // Current user avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.grey, size: 16),
                ),
                const SizedBox(width: 12),

                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _replyToCommentId == null
                            ? 'Mulai percakapan...'
                            : 'Balas @$_replyToUsername...',
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _postComment(),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      minLines: 1,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: _isPosting ? null : _postComment,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPosting ? Colors.grey[400] : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),

            // Emoji row (Instagram-like)
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 44), // Space for avatar alignment
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildEmojiButton('❤️'),
                          _buildEmojiButton('🙌'),
                          _buildEmojiButton('🔥'),
                          _buildEmojiButton('👏'),
                          _buildEmojiButton('😢'),
                          _buildEmojiButton('😍'),
                          _buildEmojiButton('😮'),
                          _buildEmojiButton('😂'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Smiley face button (like Instagram)
                  GestureDetector(
                    onTap: () {
                      // Add emoji picker functionality here
                      _focusNode.requestFocus();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[400]!, width: 1),
                      ),
                      child: Icon(
                        Icons.sentiment_satisfied_alt_outlined,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return GestureDetector(
      onTap: _isPosting ? null : () {
        final currentText = _commentController.text;
        final selection = _commentController.selection;
        final newText = currentText.replaceRange(
          selection.start,
          selection.end,
          emoji,
        );
        _commentController.text = newText;
        _commentController.selection = TextSelection.fromPosition(
          TextPosition(offset: selection.start + emoji.length),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// WIDGET KOMENTAR DENGAN DESAIN INSTAGRAM-LIKE (FLAT STRUCTURE)
class InstagramCommentTile extends StatefulWidget {
  final String articleUrl;
  final String commentId;
  final Map<String, dynamic> data;
  final Function(String, String, String, {String? rootId})? onReply;
  final bool isRootComment;
  final String? currentUserId;
  final Function(String, String, String)? onLike;
  final Function(String)? onTranslate;
  final Function(String, bool)? onDelete; // Tambahkan callback untuk hapus

  const InstagramCommentTile({
    Key? key,
    required this.articleUrl,
    required this.commentId,
    required this.data,
    this.onReply,
    this.isRootComment = false,
    this.currentUserId,
    this.onLike,
    this.onTranslate,
    this.onDelete, // Inisialisasi callback hapus
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
      return '${difference.inDays} hari';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit';
    } else {
      return 'baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final likeCount = widget.data['likes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: _photoUrl == null || _photoUrl!.isEmpty
                      ? Text(
                          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username & time
                    Row(
                      children: [
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(widget.data['timestamp']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Comment text with mention if it's a reply
                    RichText(
                      text: TextSpan(
                        children: [
                          // Show mention if this is a reply
                          if (widget.data['replyToUsername'] != null &&
                              widget.data['replyToUsername'].toString().isNotEmpty)
                            TextSpan(
                              text: '@${widget.data['replyToUsername']} ',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          // Comment text
                          TextSpan(
                            text: widget.data['comment'] ?? '',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action buttons (reply, translate)
                    Row(
                      children: [
                        if (widget.onReply != null)
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
                        // Tombol hapus untuk pemilik komentar
                        if (widget.currentUserId == widget.data['userId']) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              if (widget.onDelete != null) {
                                widget.onDelete!(widget.commentId, widget.isRootComment);
                              }
                            },
                            child: Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Show replies button (Instagram style) - hanya untuk root comments
                    if (widget.isRootComment)
                      StreamBuilder<QuerySnapshot>(
                        stream: _interactionService.getReplies(widget.articleUrl, widget.commentId),
                        builder: (context, snapshot) {
                          final replyCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          
                          if (replyCount > 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showReplies = !_showReplies;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 1,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _showReplies
                                          ? 'Sembunyikan balasan'
                                          : 'Lihat $replyCount balasan',
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
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
              // Like section
              Column(
                children: [
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
                      return GestureDetector(
                        onTap: _toggleLike,
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isLiked ? Colors.red : Colors.grey[600],
                        ),
                      );
                    },
                  ),
                  if (likeCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        likeCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Replies section - FLAT STRUCTURE seperti Instagram
          if (widget.isRootComment && _showReplies)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: StreamBuilder<QuerySnapshot>(
                stream: _interactionService.getReplies(widget.articleUrl, widget.commentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final replies = snapshot.data!.docs;
                  
                  return Column(
                    children: replies.map((replyDoc) {
                      final replyData = replyDoc.data() as Map<String, dynamic>;
                      
                      // Tampilkan semua balasan dengan struktur yang FLAT
                      // Tidak ada indentasi berlebihan, semua balasan tampil dengan level yang sama
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InstagramCommentTile(
                          key: ValueKey(replyDoc.id),
                          articleUrl: widget.articleUrl,
                          commentId: replyDoc.id,
                          data: replyData,
                          onReply: widget.onReply,
                          isRootComment: false,
                          currentUserId: widget.currentUserId,
                          onLike: widget.onLike,
                          onTranslate: widget.onTranslate,
                          onDelete: widget.onDelete, // GANTI INI, jangan pakai _showDeleteConfirmation
                        ),
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