import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Keep this for date formatting in the build method
import 'package:firebase_auth/firebase_auth.dart'; // This is crucial for authentication
import '../models/comment.dart';
import '../services/comment_api_service.dart';

class CommentSectionPopup extends StatefulWidget {
  final String articleUrl;

  const CommentSectionPopup({Key? key, required this.articleUrl}) : super(key: key);

  @override
  State<CommentSectionPopup> createState() => _CommentSectionPopupState();
}

class _CommentSectionPopupState extends State<CommentSectionPopup> {
  final _commentApiService = CommentApiService();
  final _commentController = TextEditingController();
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _commentApiService.fetchComments(widget.articleUrl);
  }

  void _postComment() {
    // 1. Dapatkan informasi pengguna yang sedang login
    final User? user = FirebaseAuth.instance.currentUser;

    // 2. Periksa apakah pengguna sudah login. Jika tidak, dia adalah tamu.
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda harus login untuk bisa berkomentar."),
          backgroundColor: Colors.orange, // Added a background color for better visibility
        ),
      );
      return; // Hentikan fungsi di sini
    }

    // 3. Periksa apakah input komentar tidak kosong
    if (_commentController.text.trim().isEmpty) return;

    // 4. Gunakan nama dari pengguna yang sudah login
    final authorName = user.displayName ?? "Pengguna Anonim";

    // 5. Kirim komentar ke backend Anda
    _commentApiService.postComment(
      widget.articleUrl,
      authorName,
      _commentController.text.trim(),
    ).then((_) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      // Muat ulang daftar komentar untuk menampilkan komentar baru
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
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          Text("Komentar", style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16)
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