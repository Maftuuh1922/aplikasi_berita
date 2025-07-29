import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  void _handleComment(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      LoginPopup.show(context, message: "Login diperlukan untuk berkomentar.");
      return;
    }
    // lanjutkan aksi komentar...
  }

  void _handleLike(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      LoginPopup.show(context, message: "Login diperlukan untuk menyukai artikel.");
      return;
    }
    // lanjutkan aksi like...
  }

  void _handleBookmark(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      LoginPopup.show(context, message: "Login diperlukan untuk menyimpan artikel.");
      return;
    }
    // lanjutkan aksi simpan...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gambar artikel
            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
              Image.network(
                article.urlToImage!,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(IconData(0xe8c3, fontFamily: 'MaterialIcons'), size: 50),
                    ),
                  );
                },
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(IconData(0xe8c3, fontFamily: 'MaterialIcons'), size: 50),
                ),
              ),

            const SizedBox(height: 16),

            // Judul artikel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                article.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Penulis dan tanggal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Oleh ${article.author}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    article.publishedAt != null
                        ? DateFormat('dd MMM yyyy').format(article.publishedAt)
                        : "Tanggal tidak tersedia",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Isi artikel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                article.description ?? "Konten tidak tersedia",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tombol aksi (Komentar, Like, Simpan)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Komentar
                ElevatedButton.icon(
                  onPressed: () => _handleComment(context),
                  icon: const Icon(Icons.comment),
                  label: const Text("Komentar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Tombol Like
                ElevatedButton.icon(
                  onPressed: () => _handleLike(context),
                  icon: const Icon(Icons.thumb_up),
                  label: const Text("Suka"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Tombol Simpan
                ElevatedButton.icon(
                  onPressed: () => _handleBookmark(context),
                  icon: const Icon(Icons.bookmark),
                  label: const Text("Simpan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class LoginPopup {
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: Text(message ?? 'Silakan login untuk melanjutkan.'),
        actions: [
          TextButton(
            onPressed: () async {
              debugPrint('DEBUG: Tombol Login di LoginPopup ditekan');
              Navigator.of(dialogContext).pop(); // Close dialog first
              await Future.delayed(const Duration(milliseconds: 200));
              if (Navigator.of(context).mounted) {
                Navigator.of(context).pushNamed('/login');
              }
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}