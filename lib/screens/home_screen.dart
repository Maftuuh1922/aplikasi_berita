import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Mengasumsikan ini berisi enum NewsSource
import '../models/article.dart';
import '../services/news_api_service.dart'; // Untuk berita internasional (GNews)
import '../services/berita_indo_api_service.dart'; // Untuk berita Indonesia
import 'article_detail_screen.dart';
import 'category_screen.dart';
import 'profile_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  List<Article> _articles = [];
  List<Article> _trendingArticles = [];
  bool _isLoading = true;
  String? _errorMessage;

  // State untuk manajemen sumber dan kategori
  NewsSource _selectedSource = NewsSource.indo;
  String _selectedCategory = 'nasional'; // Kategori API default untuk Indo
  String _displayCategory = 'all'; // Kategori yang ditampilkan di UI
  String _searchQuery = '';

  // Kategori untuk API Berita Indonesia
  final List<Map<String, String>> categoriesIndo = [
    {'key': 'nasional', 'name': 'Nasional'},
    {'key': 'ekonomi', 'name': 'Ekonomi'},
    {'key': 'olahraga', 'name': 'Olahraga'},
    {'key': 'teknologi', 'name': 'Teknologi'},
  ];

  // Kategori untuk API GNews (berita luar)
  final List<Map<String, String>> categoriesLuar = [
    {'key': 'general', 'name': 'Umum'},
    {'key': 'world', 'name': 'Dunia'},
    {'key': 'business', 'name': 'Bisnis'},
    {'key': 'technology', 'name': 'Teknologi'},
    {'key': 'sports', 'name': 'Olahraga'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  // Fungsi untuk memuat berita berdasarkan sumber yang dipilih
  Future<void> _loadNews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<Article> newArticles;
      if (_selectedSource == NewsSource.indo) {
        newArticles =
            await BeritaIndoApiService().fetchNews(category: _selectedCategory);
      } else {
        // Memanggil service GNews untuk berita luar
        newArticles =
            await NewsApiService().fetchNews(category: _selectedCategory);
      }

      if (mounted) {
        setState(() {
          _articles = newArticles;
          // Ambil 5 berita pertama sebagai trending
          _trendingArticles =
              newArticles.isNotEmpty ? newArticles.take(5).toList() : [];
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _articles = [];
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk menangani pergantian chip kategori
  void _onCategoryChipChanged(String displayCategory) {
    setState(() => _displayCategory = displayCategory);

    String apiCategory;
    if (_selectedSource == NewsSource.indo) {
      // Mapping untuk sumber berita Indonesia
      switch (displayCategory) {
        case 'sports':
          apiCategory = 'olahraga';
          break;
        case 'business':
          apiCategory = 'ekonomi';
          break;
        case 'politics':
          apiCategory = 'nasional';
          break;
        case 'science':
          apiCategory = 'teknologi';
          break;
        default:
          apiCategory = 'nasional'; // 'all'
      }
    } else {
      // Mapping untuk sumber berita GNews (luar)
      switch (displayCategory) {
        case 'sports':
          apiCategory = 'sports';
          break;
        case 'business':
          apiCategory = 'business';
          break;
        case 'politics':
          apiCategory = 'nation';
          break; // GNews pakai 'nation'
        case 'science':
          apiCategory = 'science';
          break;
        case 'health':
          apiCategory = 'health';
          break;
        default:
          apiCategory = 'general'; // 'all'
      }
    }

    // Perbarui state dan muat ulang berita
    setState(() => _selectedCategory = apiCategory);
    _loadNews();
  }

  // Fungsi untuk mengganti sumber berita (Indo/Luar)
  void _onSourceChanged(NewsSource? newSource) {
    if (newSource == null || newSource == _selectedSource) return;
    setState(() {
      _selectedSource = newSource;
      // Atur kategori default berdasarkan sumber baru
      _selectedCategory = (newSource == NewsSource.indo)
          ? categoriesIndo.first['key']!
          : categoriesLuar.first['key']!;
      _displayCategory = 'all'; // Reset chip ke 'All'
      _articles = [];
      _trendingArticles = [];
      _errorMessage = null;
    });
    _loadNews();
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          SafeArea(child: _buildHomePage()),
          CategoryScreen(activeSource: _selectedSource),
          const Center(child: Text('Halaman Cari')),
          const BookmarksScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- UI WIDGETS ---
  // (Sebagian besar kode UI Anda di bawah ini sudah bagus,
  // saya hanya melakukan sedikit penyesuaian)

  Widget _buildHomePage() {
    final filteredArticles = _articles
        .where(
            (a) => a.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return CustomScrollView(
      slivers: [
        // ... (Kode Header dan Search Bar Anda tetap sama)
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/Bebas Neue.png',
                        width: 100, height: 40, fit: BoxFit.contain),
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.notifications_outlined, size: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search for news...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
        ),
        // Switch Berita Indo/Luar
        SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Indo'),
              Switch(
                value: _selectedSource == NewsSource.luar,
                onChanged: (value) {
                  _onSourceChanged(value ? NewsSource.luar : NewsSource.indo);
                },
              ),
              const Text('Luar'),
            ],
          ),
        ),
        // Trending
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trending',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_trendingArticles.isNotEmpty)
                  _TrendingCard(article: _trendingArticles.first)
                else
                  const Text('Tidak ada berita trending.'),
              ],
            ),
          ),
        ),

        // Latest Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Berita Terbaru',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                          label: 'All',
                          isSelected: _displayCategory == 'all',
                          onTap: () => _onCategoryChipChanged('all')),
                      _CategoryChip(
                          label: 'Sports',
                          isSelected: _displayCategory == 'sports',
                          onTap: () => _onCategoryChipChanged('sports')),
                      _CategoryChip(
                          label: 'Politics',
                          isSelected: _displayCategory == 'politics',
                          onTap: () => _onCategoryChipChanged('politics')),
                      _CategoryChip(
                          label: 'Business',
                          isSelected: _displayCategory == 'business',
                          onTap: () => _onCategoryChipChanged('business')),
                      _CategoryChip(
                          label: 'Science',
                          isSelected: _displayCategory == 'science',
                          onTap: () => _onCategoryChipChanged('science')),
                      if (_selectedSource == NewsSource.luar)
                        _CategoryChip(
                            label: 'Health',
                            isSelected: _displayCategory == 'health',
                            onTap: () => _onCategoryChipChanged('health')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // News List
        if (_isLoading && _articles.isEmpty)
          const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator())))
        else if (_errorMessage != null)
          SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_errorMessage!))))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= filteredArticles.length) return null;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _NewsListItem(
                    article: filteredArticles[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => ArticleDetailScreen(
                              article: filteredArticles[index])),
                    ),
                  ),
                );
              },
              childCount: filteredArticles.length,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavTapped,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_filled), label: 'Homepage'),
        BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined), label: 'Category'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border), label: 'Bookmark'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

// ... (_TrendingCard, _CategoryChip, _NewsListItem widgets tetap sama)
class _TrendingCard extends StatelessWidget {
  final Article article;
  const _TrendingCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (c) => ArticleDetailScreen(article: article))),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(article.urlToImage ?? ''),
            fit: BoxFit.cover,
            onError: (e, s) {}, // Handle image error
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                article.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NewsListItem extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const _NewsListItem({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                article.urlToImage!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(width: 100, height: 100, color: Colors.grey[200]),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.sourceName,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(DateFormat('d MMM yyyy').format(article.publishedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
