// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_api_service.dart';
import 'article_detail_screen.dart';
import 'package:intl/intl.dart'; // <-- Perbaikan di baris ini

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Article>> _articlesFuture;
  String _selectedCategory = 'breaking-news';

  final List<Map<String, String>> categories = [
    {'key': 'breaking-news', 'name': 'Berita Terkini'},
    {'key': 'business', 'name': 'Bisnis'},
    {'key': 'technology', 'name': 'Teknologi'},
    {'key': 'sports', 'name': 'Olahraga'},
    {'key': 'entertainment', 'name': 'Hiburan'},
    {'key': 'health', 'name': 'Kesehatan'},
    {'key': 'science', 'name': 'Sains'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    setState(() {
      _articlesFuture = NewsApiService().fetchTopHeadlines(
        country: 'id',
        topic: _selectedCategory,
        lang: 'id',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Terbaru'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(category['name']!),
                    selected: _selectedCategory == category['key'],
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category['key']!;
                          _loadNews();
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Article>>(
              future: _articlesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}\nPastikan API Key valid dan koneksi internet tersedia.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada berita ditemukan.'));
                } else {
                  final articles = snapshot.data!;
                  return ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailScreen(article: article),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      article.urlToImage!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 180,
                                        color: Colors.grey[300],
                                        child: Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[600])),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10.0),
                                Text(
                                  article.title,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  article.description ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 6.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      article.sourceName,
                                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm').format(article.publishedAt),
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}