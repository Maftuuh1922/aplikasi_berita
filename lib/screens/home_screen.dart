import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/article.dart';
import '../services/news_api_service.dart';
import '../services/berita_indo_api_service.dart';
import '../services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  final User? _user = FirebaseAuth.instance.currentUser;

  List<Article> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;
  NewsSource _selectedSource = NewsSource.indo;
  String _selectedCategory = 'nasional';
  String _searchQuery = '';

  final List<Map<String, String>> categoriesIndo = [
    {'key': 'nasional', 'name': 'Nasional'},
    {'key': 'ekonomi', 'name': 'Ekonomi'},
    {'key': 'olahraga', 'name': 'Olahraga'},
    {'key': 'teknologi', 'name': 'Teknologi'},
  ];

  final List<Map<String, String>> categoriesLuar = [
    {'key': 'breaking-news', 'name': 'Terkini'},
    {'key': 'business', 'name': 'Bisnis'},
    {'key': 'sports', 'name': 'Olahraga'},
    {'key': 'technology', 'name': 'Teknologi'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Article> newArticles;
      if (_selectedSource == NewsSource.indo) {
        newArticles = await BeritaIndoApiService().fetchNews(category: _selectedCategory);
      } else {
        newArticles = await NewsApiService().fetchNews(category: _selectedCategory);
      }
      if (mounted) {
        setState(() { _articles = newArticles; _errorMessage = null; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _articles = []; _errorMessage = e.toString(); });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
  }

  void _onSourceChanged(NewsSource? newSource) {
    if (newSource == null || newSource == _selectedSource) return;
    setState(() {
      _selectedSource = newSource;
      _selectedCategory = (newSource == NewsSource.indo) ? categoriesIndo.first['key']! : categoriesLuar.first['key']!;
      _articles = [];
      _errorMessage = null;
    });
    _loadNews();
  }

  void _onCategoryChipChanged(String newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      _articles = [];
      _errorMessage = null;
    });
    _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          SafeArea(child: Column(children: [_buildHeaderAndFilters(), Expanded(child: _buildNewsPage())])),
          CategoryScreen(activeSource: _selectedSource),
          const Center(child: Text('Halaman Cari')),
          const BookmarksScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeaderAndFilters() {
    final currentCategories = _selectedSource == NewsSource.indo ? categoriesIndo : categoriesLuar;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Beranda', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<NewsSource>(
                    value: _selectedSource,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    items: const [
                      DropdownMenuItem(value: NewsSource.indo, child: Row(children: [Text('🇮🇩'), SizedBox(width: 8), Text('Indonesia')])),
                      DropdownMenuItem(value: NewsSource.luar, child: Row(children: [Text('🌍'), SizedBox(width: 8), Text('Luar Negeri')])),
                    ],
                    onChanged: _onSourceChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari berita...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: currentCategories.length,
            itemBuilder: (context, index) {
              final category = currentCategories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(category['name']!),
                  selected: _selectedCategory == category['key'],
                  onSelected: (selected) { if (selected) _onCategoryChipChanged(category['key']!); },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, color: _selectedCategory == category['key'] ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyLarge?.color),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _selectedCategory == category['key'] ? Colors.transparent : Colors.grey.shade300)),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewsPage() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_errorMessage!)));

    final filteredArticles = _articles.where((a) => a.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    if (filteredArticles.isEmpty) return const Center(child: Text('Tidak ada berita ditemukan.'));

    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredArticles.length,
        itemBuilder: (context, idx) => _NewsCard(
          article: filteredArticles[idx],
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ArticleDetailScreen(article: filteredArticles[idx]))),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavTapped,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Kategori'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Tersimpan'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const _NewsCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    article.urlToImage!, width: 110, height: 110, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(width: 110, height: 110, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(article.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          Expanded(child: Text(article.sourceName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM').format(article.publishedAt), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}