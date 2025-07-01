import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/comment.dart';
import '../services/comment_api_service.dart'; // <-- Gunakan service API baru

class CommentSectionWidget extends StatefulWidget {
  final String articleUrl;

  const CommentSectionWidget({Key? key, required this.articleUrl}) : super(key: key);

  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final _commentApiService = CommentApiService();
  final _commentController = TextEditingController();
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    // Ambil data komentar dari API saat widget pertama kali dibuat
    _commentsFuture = _commentApiService.fetchComments(widget.articleUrl);
  }

  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;

    _commentApiService.postComment(
      widget.articleUrl,
      'Pengguna Flutter', // Nama bisa dibuat dinamis nanti
      _commentController.text.trim(),
    ).then((_) {
      // Jika berhasil, bersihkan input dan muat ulang daftar komentar
      _commentController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _commentsFuture = _commentApiService.fetchComments(widget.articleUrl);
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim: $error")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text("Komentar", style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(height: 1),
          // Gunakan FutureBuilder karena data diambil dari API
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Gagal memuat: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Jadilah yang pertama berkomentar."));
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(comment.author[0])),
                      title: Text(comment.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.text),
                      trailing: Text(DateFormat('HH:mm').format(comment.timestamp), style: Theme.of(context).textTheme.bodySmall),
                    );
                  },
                );
              },
            ),
          ),
          // Form Input Komentar
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Tulis komentar...",
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}