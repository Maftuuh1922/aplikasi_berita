// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/article.dart';
import '../services/news_api_service.dart';
import 'article_detail_screen.dart';
import 'category_screen.dart';

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

  int _visibleCount = 5;
  bool _showAll = false;

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadNews();
    }
  }

  // REVISI FINAL: Method ini disesuaikan dengan service Anda (GNews & Berita Indo API)
  void _loadNews({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _articles = [];
        _hasMore = true;
        _showAll = false;
      });
    }
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      List<Article> newArticles = [];

      if (_selectedSource == NewsSource.indo) {
        // Panggil service Berita Indonesia
        newArticles = await BeritaIndoApiService().fetchAntaraNews();
        _hasMore = false; // API ini tidak ada pagination
      } else {
        // Panggil service GNews (luar negeri)
        newArticles = await NewsApiService().fetchTopHeadlines(
          country: 'id',
          page: _currentPage,
          max: 10,
        );
      }

      setState(() {
        if (newArticles.isNotEmpty) {
          if (reset) {
            _articles = newArticles;
          } else {
            _articles.addAll(newArticles);
          }
          _currentPage++;
        } else {
          _hasMore = false;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat berita: $e')),
        );
      }
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
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
    final filtered = _searchQuery.isEmpty
        ? _articles
        : _articles
        .where((a) =>
    a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (a.description ?? '')
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    _suggestions = _searchQuery.isEmpty
        ? []
        : _articles
        .where((a) =>
        a.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .map((a) => a.title)
        .take(5)
        .toSet()
        .toList();

    final withImage = filtered
        .where((a) => a.urlToImage != null && a.urlToImage!.isNotEmpty)
        .toList();
    final withoutImage = filtered
        .where((a) => a.urlToImage == null || a.urlToImage!.isEmpty)
        .toList();
    final sorted = [...withImage, ...withoutImage];

    if (_articles.isEmpty && _isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sorted.isEmpty) {
      return const Center(child: Text('Tidak ada berita ditemukan.'));
    }

    final int showCount = _showAll
        ? sorted.length
        : (_visibleCount < sorted.length ? _visibleCount : sorted.length);
    final List<Article> visibleArticles = sorted.take(showCount).toList();
    final bool showSeeMore = !_showAll && sorted.length > _visibleCount;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: visibleArticles.length +
          (showSeeMore ? 1 : 0) +
          (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, idx) {
        if (idx < visibleArticles.length) {
          final article = visibleArticles[idx];
          return _NewsCard(
            article: article,
            isFeatured: idx == 0,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ArticleDetailScreen(article: article)));
            },
          );
        }
        if (showSeeMore && idx == visibleArticles.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: ElevatedButton(
                onPressed: () => setState(() => _showAll = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text('Lihat Selengkapnya',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          );
        }
        if (_isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return const SizedBox.shrink();
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Berita Terbaru',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 8),
                ],
              ),
            ),
            Container(
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(25),
                child: TextField(
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Cari berita...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            SizedBox(
              height: 45,
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
                          // Kategori saat ini tidak berpengaruh pada _loadNews
                          // karena service tidak mendukungnya, tapi UI tetap bisa diupdate
                          setState(() => _selectedCategory = category['key']!);
                        }
                      },
                      selectedColor: const Color(0xFF8B5CF6),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[700]),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<NewsSource>(
                segments: const <ButtonSegment<NewsSource>>[
                  ButtonSegment<NewsSource>(
                      value: NewsSource.indo, label: Text('Indonesia')),
                  ButtonSegment<NewsSource>(
                      value: NewsSource.luar, label: Text('Luar Negeri')),
                ],
                selected: <NewsSource>{_selectedSource},
                onSelectionChanged: (Set<NewsSource> newSelection) {
                  setState(() {
                    _selectedSource = newSelection.first;
                    _loadNews(reset: true);
                  });
                },
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _selectedIndex = index),
                children: [
                  _buildNewsPage(),
                  const CategoryScreen(),
                  const Center(child: Text('Halaman Cari')),
                  const Center(child: Text('Halaman Tersimpan')),
                  const Center(child: Text('Halaman Profil')),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF8B5CF6) : Colors.grey[500]),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isActive ? const Color(0xFF8B5CF6) : Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Article article;
  final bool isFeatured;
  final VoidCallback onTap;

  const _NewsCard(
      {required this.article, required this.onTap, this.isFeatured = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: isFeatured ? _buildFeaturedCard() : _buildRegularCard(),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (article.urlToImage != null)
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              article.urlToImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
              const SizedBox(height: 180, child: Icon(Icons.image_not_supported)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(article.sourceName,
                      style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w500)),
                  Text(DateFormat('dd MMM, HH:mm').format(article.publishedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegularCard() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          if (article.urlToImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                article.urlToImage!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox(
                    width: 80, height: 80, child: Icon(Icons.image_not_supported)),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(article.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(article.sourceName,
                          style: const TextStyle(
                              color: Color(0xFF6366F1), fontSize: 11)),
                      Text(
                          DateFormat('dd MMM, HH:mm')
                              .format(article.publishedAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}