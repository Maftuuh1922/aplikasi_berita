// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/article.dart'; // Changed to lowercase
import '../services/news_api_service.dart';
import 'article_detail_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Article>> _articlesFuture;
  String _selectedCategory =
      'breaking-news'; // Changed from 'general' to 'breaking-news'

  int _selectedIndex = 0;

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
        topic: _selectedCategory, // Changed from category to topic
        lang: 'id', // Added language parameter
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Jika index 0 (Home), tetap tampilkan berita
      // Untuk index lain, bisa tambahkan konten lain sesuai kebutuhan
    });
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      // Home: daftar berita
      return Column(
        children: [
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(category['name']!),
                    selected: _selectedCategory == category['key'],
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['key']!;
                        _loadNews();
                      });
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
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'Error: ${snapshot.error}\nPastikan API Key valid dan koneksi internet tersedia.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Tidak ada berita ditemukan.'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      Article article = snapshot.data![index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ArticleDetailScreen(article: article),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (article.urlToImage != null &&
                                    article.urlToImage!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      article.urlToImage!,
                                      fit: BoxFit.cover,
                                      height: 180,
                                      width: double.infinity,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: 180,
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 180,
                                        color: Colors.grey[300],
                                        child: Center(
                                            child: Icon(
                                                Icons.image_not_supported,
                                                size: 60,
                                                color: Colors.grey[600])),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 10.0),
                                Text(
                                  article.title,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6.0),
                                Text(
                                  article.description ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                SizedBox(height: 6.0),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      article.sourceName,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm')
                                          .format(article.publishedAt),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600]),
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
      );
    } else if (_selectedIndex == 1) {
      return Center(child: Text('For You', style: TextStyle(fontSize: 24)));
    } else if (_selectedIndex == 2) {
      return Center(child: Text('Search', style: TextStyle(fontSize: 24)));
    } else if (_selectedIndex == 3) {
      return Center(child: Text('Profile', style: TextStyle(fontSize: 24)));
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Berita Terbaru'),
        backgroundColor: Color(0xFF8338ec), // AppBar sesuai palet warna
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF8338ec),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        showUnselectedLabels: true,
        elevation: 12,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'For You',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
