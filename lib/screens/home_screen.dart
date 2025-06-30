// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/berita_indo_api_service.dart' as indo_api;
import '../services/news_api_service.dart';
import '../services/contextual_web_news_service.dart' as cwnews;
import '../services/realtime_news_service.dart' as rtnews;
import 'article_detail_screen.dart';
import 'package:intl/intl.dart';
import 'category_screen.dart'; // Tambahkan import ini

// Pindahkan enum ke sini (top-level)
enum NewsSource { indo, luar }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'breaking-news';
  int _selectedIndex = 0;
  String _searchQuery = '';
  final PageController _pageController = PageController();

  // Pagination
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<Article> _articles = [];
  final ScrollController _scrollController = ScrollController();

  final FocusNode _searchFocusNode = FocusNode();
  List<String> _suggestions = [];

  NewsSource _selectedSource = NewsSource.indo;

  // Tambahkan di bagian deklarasi variabel state
  int _visibleCount = 5; // Jumlah berita awal yang ditampilkan
  bool _showAll = false; // Kontrol apakah semua berita ditampilkan

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
    _loadNews(reset: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
      _loadNews();
    }
  }

  void _loadNews({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _articles = [];
        _hasMore = true;
        _showAll = false; // Reset tombol "Lihat Selengkapnya"
      });
    }
    if (!_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      List<Article> newArticles = [];
      if (_selectedSource == NewsSource.indo) {
        newArticles = await NewsApiService().fetchTopHeadlines(
          country: 'id',
          max: 10,
          page: _currentPage,
        );
      } else {
        newArticles = await NewsApiService().fetchTopHeadlines(
          country: 'id',
          page: _currentPage,
        );
      }

      setState(() {
        if (reset) {
          _articles = newArticles;
        } else {
          _articles.addAll(newArticles);
        }
        _isLoadingMore = false;
        _hasMore = newArticles.isNotEmpty;
        if (_hasMore) _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _hasMore = false;
      });
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildNewsPage() {
    // Filter by search
    final filtered = _searchQuery.isEmpty
        ? _articles
        : _articles.where((a) =>
            a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (a.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    // Saran judul berita
    _suggestions = _searchQuery.isEmpty
        ? []
        : _articles
            .where((a) => a.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .map((a) => a.title)
            .toSet()
            .toList();

    // Sort: berita dengan gambar di atas
    final withImage = filtered.where((a) => a.urlToImage != null && a.urlToImage!.isNotEmpty).toList();
    final withoutImage = filtered.where((a) => a.urlToImage == null || a.urlToImage!.isEmpty).toList();
    final sorted = [...withImage, ...withoutImage];

    if (_articles.isEmpty && _isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sorted.isEmpty) {
      return const Center(child: Text('Tidak ada berita ditemukan.'));
    }

    // --- FITUR LIHAT SELENGKAPNYA ---
    // Tentukan jumlah berita yang akan ditampilkan
    final int showCount = _showAll ? sorted.length : (_visibleCount < sorted.length ? _visibleCount : sorted.length);
    final List<Article> visibleArticles = sorted.take(showCount).toList();
    final bool showSeeMore = !_showAll && sorted.length > _visibleCount;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: visibleArticles.length + (showSeeMore ? 1 : 0) + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, idx) {
        if (idx == 0 && visibleArticles.isNotEmpty) {
          // FEATURED NEWS
          return _NewsCard(
            article: visibleArticles[0],
            isFeatured: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ArticleDetailScreen(article: visibleArticles[0]),
              ));
            },
          );
        }
        // Tombol "Lihat Selengkapnya"
        if (showSeeMore && idx == visibleArticles.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAll = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text('Lihat Selengkapnya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          );
        }
        // Loading indicator jika sedang memuat lebih banyak
        if (_isLoadingMore && idx == visibleArticles.length + (showSeeMore ? 1 : 0)) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Daftar berita biasa
        final article = visibleArticles[idx];
        return _NewsCard(
          article: article,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Berita Terbaru', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                      ),
                      const Text('Live Update', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            // SEARCH BAR
            Container(
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(25),
                    child: TextField(
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Cari berita terkini...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                  if (_searchFocusNode.hasFocus && _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, idx) {
                          final suggestion = _suggestions[idx];
                          return ListTile(
                            title: Text(suggestion, style: const TextStyle(fontSize: 15)),
                            onTap: () {
                              setState(() {
                                _searchQuery = suggestion;
                                _searchFocusNode.unfocus();
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // CATEGORY TABS
            Container(
              height: 45,
              margin: const EdgeInsets.only(top: 10, bottom: 5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isActive = _selectedCategory == category['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(category['name']!),
                      selected: isActive,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category['key']!;
                          });
                          _loadNews(reset: true);
                        }
                      },
                      selectedColor: const Color(0xFF8B5CF6),
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: TextStyle(color: isActive ? Colors.white : Colors.grey[700]),
                    ),
                  );
                },
              ),
            ),
            // PILIH SUMBER BERITA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<NewsSource>(
                      title: const Text('Berita Indonesia'),
                      value: NewsSource.indo,
                      groupValue: _selectedSource,
                      onChanged: (val) {
                        setState(() {
                          _selectedSource = val!;
                        });
                        _loadNews(reset: true);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<NewsSource>(
                      title: const Text('Berita Luar'),
                      value: NewsSource.luar,
                      groupValue: _selectedSource,
                      onChanged: (val) {
                        setState(() {
                          _selectedSource = val!;
                        });
                        _loadNews(reset: true);
                      },
                    ),
                  ),
                ],
              ),
            ),
            // PAGE VIEW
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: [
                  _buildNewsPage(),
                  CategoryScreen(), // Ganti halaman kategori di sini
                  Center(child: Text('Cari', style: TextStyle(color: Colors.grey))),
                  Center(child: Text('Tersimpan', style: TextStyle(color: Colors.grey))),
                  Center(child: Text('Profil', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      ),
      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: Border(top: BorderSide(color: Colors.black12)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        padding: const EdgeInsets.only(bottom: 15, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Beranda', 0),
            _buildNavItem(Icons.category, 'Kategori', 1),
            _buildNavItem(Icons.search, 'Cari', 2),
            _buildNavItem(Icons.bookmark, 'Tersimpan', 3),
            _buildNavItem(Icons.person, 'Profil', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0x1A8B5CF6),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Color(0xFF8B5CF6) : Colors.grey[500]),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? Color(0xFF8B5CF6) : Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Widget untuk Card Berita dengan animasi hover
class _NewsCard extends StatefulWidget {
  final Article article;
  final bool isFeatured;
  final VoidCallback onTap;

  const _NewsCard({
    required this.article,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final radius = widget.isFeatured ? 20.0 : 12.0;
    final height = widget.isFeatured ? 180.0 : 80.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: EdgeInsets.only(bottom: widget.isFeatured ? 20 : 15),
            padding: widget.isFeatured ? EdgeInsets.zero : const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: widget.isFeatured ? 15 : 8, offset: Offset(0, widget.isFeatured ? 8 : 4))],
            ),
            child: widget.isFeatured
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                          child: Image.network(
                            article.urlToImage!,
                            height: height,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _imagePlaceholder(height: height, radius: radius),
                          ),
                        )
                      else
                        _imagePlaceholder(height: height, radius: radius),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(article.sourceName, style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w500, fontSize: 12)),
                                ),
                                Text(DateFormat('dd MMM yyyy, HH:mm').format(article.publishedAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: Image.network(
                            article.urlToImage!,
                            width: height,
                            height: height,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _imagePlaceholder(height: height, radius: radius),
                          ),
                        )
                      else
                        _imagePlaceholder(height: height, radius: radius),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(article.sourceName, style: TextStyle(color: Color(0xFF6366F1), fontSize: 11)),
                                ),
                                Text(DateFormat('dd MMM yyyy, HH:mm').format(article.publishedAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Tambahkan tombol Baca Selengkapnya
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArticleDetailScreen(article: article),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Baca Selengkapnya',
                                  style: TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder({double height = 80, double radius = 12}) {
    return Container(
      width: height,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: const Icon(Icons.image, color: Colors.white54, size: 40),
    );
  }
}
