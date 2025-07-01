import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bookmark_service.dart';
import 'article_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artikel Tersimpan'),
      ),
      body: Consumer<BookmarkService>(
        builder: (context, bookmarkService, child) {
          final bookmarkedArticles = bookmarkService.bookmarkedArticles;
          if (bookmarkedArticles.isEmpty) {
            return const Center(child: Text('Anda belum menyimpan artikel apapun.'));
          }
          return ListView.builder(
            itemCount: bookmarkedArticles.length,
            itemBuilder: (context, index) {
              final article = bookmarkedArticles[index];
              return ListTile(
                title: Text(article.title),
                subtitle: Text(article.sourceName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(article: article),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}