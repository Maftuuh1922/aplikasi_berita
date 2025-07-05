import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/comment.dart';
import '../services/auth_service.dart';
import '../services/comment_api_service.dart';

class CommentSectionPopup extends StatefulWidget {
  final String articleUrl;
  const CommentSectionPopup({super.key, required this.articleUrl});

  @override
  State<CommentSectionPopup> createState() => _CommentSectionPopupState();
}

class _CommentSectionPopupState extends State<CommentSectionPopup> {
  final _api          = CommentApiService();
  final _cComment     = TextEditingController();
  final _cReply       = TextEditingController();
  late Future<List<Comment>> _commentsFut;

  String? _replyingToId;
  bool _liked = false, _saved = false;

  @override
  void initState() {
    super.initState();
    _commentsFut = _api.fetchComments(widget.articleUrl);
  }

  /* -------------------------- ACTIONS -------------------------- */
  Future<void> _postComment() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return _needLogin();

    if (_cComment.text.trim().isEmpty) return;
    await _api.postComment(widget.articleUrl,
        user.displayName ?? 'Anonim', _cComment.text.trim());
    _cComment.clear();
    _refreshComments();
  }

  Future<void> _postReply(String parent) async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return _needLogin();
    if (_cReply.text.trim().isEmpty) return;

    await _api.postReply(parent, user.displayName ?? 'Anonim', _cReply.text);
    _cReply.clear();
    _replyingToId = null;
    _refreshComments();
  }

  // Method _likeComment yang hilang - TAMBAHAN INI
  Future<void> _likeComment(String commentId) async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return _needLogin();

    try {
      // Panggil API untuk like/unlike comment
      await _api.likeComment(commentId);
      // Refresh comments untuk update UI
      _refreshComments();
    } catch (e) {
      // Handle error jika perlu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _toggleLikeArticle() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return _needLogin();
    setState(() => _liked = !_liked);
    _api.likeArticle(widget.articleUrl, _liked);
  }

  void _toggleSaveArticle() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return _needLogin();
    setState(() => _saved = !_saved);
    _api.saveArticle(widget.articleUrl, _saved);
  }

  void _needLogin() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Silakan login terlebih dahulu'),
    backgroundColor: Colors.orange,
  ));

  void _refreshComments() =>
      setState(() => _commentsFut = _api.fetchComments(widget.articleUrl));

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
    child: FutureBuilder<List<Comment>>(
      future: _commentsFut,
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text(snap.error.toString()));
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(child: Text('Belum ada komentar'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (c, i) => _commentTile(list[i]),
        );
      },
    ),
  );

  Widget _commentTile(Comment com) {
    final init = com.author.isNotEmpty ? com.author[0].toUpperCase() : '?';
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: CircleAvatar(
          backgroundImage:
          com.authorPhoto != null ? NetworkImage(com.authorPhoto!) : null,
          child: com.authorPhoto == null ? Text(init) : null,
        ),
        title:
        Text(com.author, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    com.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: com.isLiked ? Colors.red : Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${com.likeCount}',
                    style: TextStyle(
                        fontSize: 12,
                        color: com.isLiked ? Colors.red : Colors.grey[600])),
              ]),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () async {
                final user = await AuthService().getCurrentUser();
                if (user == null) return _needLogin();
                setState(() => _replyingToId = com.id);
              },
              child: Row(children: [
                const Icon(Icons.reply, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('Balas',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
            if (com.replyCount > 0) ...[
              const SizedBox(width: 16),
              Text('${com.replyCount} balasan',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ])
        ]),
      ),
      if (_replyingToId == com.id) _replyBox(com.id),
    ]);
  }

  Widget _replyBox(String parent) => Container(
    margin: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
        color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: _cReply,
          decoration: const InputDecoration(
              hintText: 'Balas...', border: InputBorder.none),
          maxLines: null,
        ),
      ),
      IconButton(
          icon: const Icon(Icons.send, size: 20),
          onPressed: () => _postReply(parent),
          color: Theme.of(context).primaryColor),
      IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () {
            setState(() {
              _replyingToId = null;
              _cReply.clear();
            });
          },
          color: Colors.grey[600]),
    ]),
  );

  Widget _commentInput(AppUser? user) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(children: [
      if (user?.photoUrl != null)
        CircleAvatar(radius: 16, backgroundImage: NetworkImage(user!.photoUrl!))
      else
        const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: _cComment,
          decoration: const InputDecoration(
              hintText: 'Tulis komentar...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16)),
          maxLines: null,
        ),
      ),
      IconButton(
          icon: const Icon(Icons.send),
          onPressed: _postComment,
          color: Theme.of(context).primaryColor)
    ]),
  );
}