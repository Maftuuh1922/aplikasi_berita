import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Assuming this contains NewsSource enum or similar
import '../models/article.dart';
import '../services/news_api_service.dart'; // For international news
import '../services/berita_indo_api_service.dart'; // For Indonesian news
import '../services/auth_service.dart'; // Your custom authentication service
import 'article_detail_screen.dart';
import 'category_screen.dart';
import 'profile_screen.dart';
import 'bookmarks_screen.dart';

// Removed duplicate NewsSource enum - using the one from main.dart instead

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService(); // Your custom AuthService
  // Removed: final User? _user = FirebaseAuth.instance.currentUser;
  // This was removed because we are migrating away from Firebase.
  // If user data is needed, it should be fetched from the new backend.

  List<Article> _articles = [];
  List<Article> _trendingArticles = [];
  bool _isLoading = true;
  String? _errorMessage;
  NewsSource _selectedSource = NewsSource.indo;
  String _selectedCategory = 'nasional';
  String _searchQuery = '';
  String _displayCategory = 'all'; // Added missing state variable

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

  // Added missing method: Get current display category
  String _getCurrentDisplayCategory() {
    return _displayCategory;
  }

  // Added missing method: Handle category chip changes
  void _onCategoryChipChanged(String category) {
    setState(() {
      _displayCategory = category;
    });

    // Map display categories to actual API categories
    String apiCategory;
    if (_selectedSource == NewsSource.indo) {
      switch (category) {
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
        case 'all':
        default:
          apiCategory = 'nasional';
          break;
      }
    } else {
      // For NewsSource.luar (international news)
      switch (category) {
        case 'sports':
          apiCategory = 'sports';
          break;
        case 'business':
          apiCategory = 'business';
          break;
        case 'politics':
          apiCategory = 'breaking-news';
          break;
        case 'science':
          apiCategory = 'technology';
          break;
        case 'health':
          apiCategory = 'health';
          break;
        case 'travel':
          apiCategory = 'travel';
          break;
        case 'all':
        default:
          apiCategory = 'breaking-news';
          break;
      }
    }

    // Update selected category and reload news if category changed
    if (_selectedCategory != apiCategory) {
      setState(() {
        _selectedCategory = apiCategory;
      });
      _loadNews();
    }
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
        setState(() {
          _articles = newArticles;
          _trendingArticles = newArticles.take(5).toList();
          _errorMessage = null;
        });
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
          const ProfileScreen(), // ProfileScreen is now Firebase-independent
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      slivers: [
        // Header dengan logo dan notifikasi
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: Image.asset(
                          'assets/Bebas Neue.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'FOKUS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.notifications_outlined, size: 24),
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: Icon(Icons.tune, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ),

        // Trending Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trending',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to trending page or show more trending articles
                        print('See all trending tapped');
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_trendingArticles.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(article: _trendingArticles.first),
                        ),
                      );
                    },
                    child: _TrendingCard(article: _trendingArticles.first),
                  ),
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
                const Text(
                  'Latest',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Category chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'All',
                        isSelected: _getCurrentDisplayCategory() == 'all',
                        onTap: () => _onCategoryChipChanged('all'),
                      ),
                      _CategoryChip(
                        label: 'Sports',
                        isSelected: _getCurrentDisplayCategory() == 'sports',
                        onTap: () => _onCategoryChipChanged('sports'),
                      ),
                      _CategoryChip(
                        label: 'Politics',
                        isSelected: _getCurrentDisplayCategory() == 'politics',
                        onTap: () => _onCategoryChipChanged('politics'),
                      ),
                      _CategoryChip(
                        label: 'Business',
                        isSelected: _getCurrentDisplayCategory() == 'business',
                        onTap: () => _onCategoryChipChanged('business'),
                      ),
                      _CategoryChip(
                        label: 'Health',
                        isSelected: _getCurrentDisplayCategory() == 'health',
                        onTap: () => _onCategoryChipChanged('health'),
                      ),
                      _CategoryChip(
                        label: 'Travel',
                        isSelected: _getCurrentDisplayCategory() == 'travel',
                        onTap: () => _onCategoryChipChanged('travel'),
                      ),
                      _CategoryChip(
                        label: 'Science',
                        isSelected: _getCurrentDisplayCategory() == 'science',
                        onTap: () => _onCategoryChipChanged('science'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // News List
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_errorMessage!),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final filteredArticles = _articles
                    .where((a) => a.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                if (index >= filteredArticles.length) return null;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _NewsListItem(
                    article: filteredArticles[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ArticleDetailScreen(article: filteredArticles[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Homepage'),
          BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmark'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Article article;
  const _TrendingCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image
            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
              Image.network(
                article.urlToImage!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Europe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'BBC News',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.schedule, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM').format(article.publishedAt),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                    ? Image.network(
                  article.urlToImage!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.sourceName,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Time and source
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM').format(article.publishedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}