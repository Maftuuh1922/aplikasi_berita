import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Add this import for ImageFilter
import '../main.dart'; // Mengasumsikan ini berisi enum NewsSource
import '../models/article.dart';
import '../services/news_api_service.dart'; // Untuk berita internasional (GNews)
import '../services/berita_indo_api_service.dart'; // Untuk berita Indonesia
import 'article_webview_screen.dart'; // Fix: Import ArticleWebviewScreen instead of article_detail_screen
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
  final ScrollController _scrollController = ScrollController();

  // 1. Tambahkan variabel state ini
  bool _showSearchBar = true;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 1. Tambahkan variabel untuk track search focus
  bool _isSearchFocused = false;

  List<Article> _articles = [];
  List<Article> _trendingArticles = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showTrendingAndCategories = true;

  // State untuk manajemen sumber dan kategori
  NewsSource _selectedSource = NewsSource.indo;
  String _selectedCategory = 'nasional';
  String _displayCategory = 'all';

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
    _setupScrollListener();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Tambahkan focus listener
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  // Setup scroll listener to hide/show trending and categories
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 200) {
        // Hide trending jika tidak sedang search dan search tidak fokus
        if (_showTrendingAndCategories && _searchQuery.isEmpty && !_isSearchFocused) {
          setState(() => _showTrendingAndCategories = false);
        }
        if (_showSearchBar) {
          setState(() => _showSearchBar = false);
          _searchFocusNode.unfocus();
        }
      } else if (_scrollController.offset <= 200) {
        if (!_showTrendingAndCategories && _searchQuery.isEmpty && !_isSearchFocused) {
          setState(() => _showTrendingAndCategories = true);
        }
        if (!_showSearchBar) {
          setState(() => _showSearchBar = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _navigateToArticle(BuildContext context, Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleWebviewScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          _buildHomePage(),
          CategoryScreen(activeSource: _selectedSource),
          const BookmarksScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      Colors.black.withOpacity(0.1),
                      Colors.grey[900]!.withOpacity(0.3),
                    ]
                  : [
                      Colors.white.withOpacity(0.4),
                      Colors.grey[50]!.withOpacity(0.6),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark 
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
                spreadRadius: -10,
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 65, // Slightly increased height
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced vertical padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: _selectedIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onNavTapped(0),
                  ),
                  _buildNavItem(
                    icon: _selectedIndex == 1 ? Icons.dashboard_rounded : Icons.dashboard_outlined,
                    isSelected: _selectedIndex == 1,
                    onTap: () => _onNavTapped(1),
                  ),
                  _buildNavItem(
                    icon: _selectedIndex == 2 ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onNavTapped(2),
                  ),
                  _buildNavItem(
                    icon: _selectedIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded,
                    isSelected: _selectedIndex == 3,
                    onTap: () => _onNavTapped(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: isSelected 
              ? (isDark ? Colors.blue[300] : Colors.blue[500])?.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 50, // Fixed height to prevent overflow
            margin: const EdgeInsets.symmetric(horizontal: 2), // Small margin
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isDark ? Colors.blue[400] : Colors.blue[500])?.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? Border.all(
                color: (isDark ? Colors.blue[300] : Colors.blue[500])!.withOpacity(0.4),
                width: 1.5,
              ) : null,
            ),
            child: Center( // Use Center instead of Column to prevent overflow
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDark ? Colors.blue[300] : Colors.blue[500])?.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22, // Slightly smaller icon
                  color: isSelected 
                      ? (isDark ? Colors.blue[300] : Colors.blue[600])
                      : (isDark ? Colors.grey[300] : Colors.grey[500]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 7. Update filter artikel untuk menggunakan _searchQuery dari controller
    final filteredArticles = _articles
        .where((a) => a.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Dynamic Header
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          expandedHeight: 100, // Kurangi dari 110 ke 100
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.black.withOpacity(0.3),
                            Colors.grey[900]!.withOpacity(0.6),
                          ]
                        : [
                            Colors.white.withOpacity(0.8),
                            Colors.grey[50]!.withOpacity(0.9),
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 5. Logo with search icon when search is hidden
                        GestureDetector(
                          onTap: () {
                            if (!_showSearchBar) {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.blue[400]!, Colors.blue[600]!]
                                    : [Colors.blue[500]!, Colors.blue[700]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'FOKUS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (!_showSearchBar) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // Ganti bagian dropdown bendera dalam _buildHomePage() dengan ini:
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          Colors.black.withOpacity(0.2),
                                          Colors.grey[900]!.withOpacity(0.4),
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.7),
                                          Colors.grey[50]!.withOpacity(0.8),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<NewsSource>(
                                  value: _selectedSource,
                                  onChanged: _onSourceChanged,
                                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                                  items: [
                                    DropdownMenuItem(
                                      value: NewsSource.indo,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              gradient: const LinearGradient(
                                                colors: [Colors.red, Colors.white, Colors.red],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ID',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: NewsSource.luar,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              gradient: LinearGradient(
                                                colors: [Colors.blue[700]!, Colors.blue[900]!],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.public_rounded, size: 12, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'EN',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                                  ),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 6. Tambahkan Search Bar setelah SliverAppBar
        if (_showSearchBar) ...[
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8), // Ubah dari 20 ke 8
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(14), // Kurangi dari 16 ke 14
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.black.withOpacity(0.2),
                                Colors.grey[900]!.withOpacity(0.4),
                              ]
                            : [
                                Colors.white.withOpacity(0.7),
                                Colors.grey[50]!.withOpacity(0.8),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari berita...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey[800]?.withOpacity(0.3)
                            : Colors.grey[100]?.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.blue[400]! : Colors.blue[500]!,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Enhanced Trending Section
        if (_showTrendingAndCategories && _searchQuery.isEmpty && !_isSearchFocused) ...[
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16), // Ubah dari EdgeInsets.all(20)
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(18), // Kurangi dari 20 ke 18
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.black.withOpacity(0.2),
                                Colors.grey[900]!.withOpacity(0.4),
                              ]
                            : [
                                Colors.white.withOpacity(0.7),
                                Colors.grey[50]!.withOpacity(0.8),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Trending',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_trendingArticles.isNotEmpty)
                          _TrendingCard(article: _trendingArticles.first, isDark: isDark)
                        else
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Tidak ada berita trending',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Enhanced Category Chips
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berita Terbaru',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _CategoryChip(
                            label: 'Semua',
                            isSelected: _displayCategory == 'all',
                            onTap: () => _onCategoryChipChanged('all'),
                            isDark: isDark,
                          ),
                          _CategoryChip(
                            label: 'Olahraga',
                            isSelected: _displayCategory == 'sports',
                            onTap: () => _onCategoryChipChanged('sports'),
                            isDark: isDark,
                          ),
                          _CategoryChip(
                            label: 'Politik',
                            isSelected: _displayCategory == 'politics',
                            onTap: () => _onCategoryChipChanged('politics'),
                            isDark: isDark,
                          ),
                          _CategoryChip(
                            label: 'Bisnis',
                            isSelected: _displayCategory == 'business',
                            onTap: () => _onCategoryChipChanged('business'),
                            isDark: isDark,
                          ),
                          _CategoryChip(
                            label: 'Teknologi',
                            isSelected: _displayCategory == 'science',
                            onTap: () => _onCategoryChipChanged('science'),
                            isDark: isDark,
                          ),
                          if (_selectedSource == NewsSource.luar)
                            _CategoryChip(
                              label: 'Kesehatan',
                              isSelected: _displayCategory == 'health',
                              onTap: () => _onCategoryChipChanged('health'),
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Enhanced News List
        if (_isLoading && _articles.isEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_errorMessage != null)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadNews,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= filteredArticles.length) return null;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // Kurangi dari 8 ke 6
                  child: _NewsListItem(
                    article: filteredArticles[index],
                    onTap: () => _navigateToArticle(context, filteredArticles[index]),
                    isDark: isDark,
                  ),
                );
              },
              childCount: filteredArticles.length,
            ),
          ),

        // Bottom padding for navigation
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Article article;
  final bool isDark;
  const _TrendingCard({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => ArticleWebviewScreen(article: article),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  article.urlToImage ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
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
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TRENDING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        constraints: const BoxConstraints(
          minHeight: 40,
          maxHeight: 40,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isDark
                      ? [Colors.blue[400]!, Colors.blue[600]!]
                      : [Colors.blue[500]!, Colors.blue[700]!],
                )
              : null,
          color: isSelected
              ? null
              : isDark
                  ? Colors.grey[800]?.withOpacity(0.6)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.grey[600]!.withOpacity(0.3)
                      : Colors.grey[300]!,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.blue[400] : Colors.blue[500])!
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? Colors.grey[300]
                      : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _NewsListItem extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final bool isDark;

  const _NewsListItem({
    required this.article,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey[900]?.withOpacity(0.3)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Enhanced Image Container
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                      ? Image.network(
                          article.urlToImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(
                            Icons.image_not_supported_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                        )
                      : Icon(
                          Icons.article_rounded,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Enhanced Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.sourceName,
                      style: TextStyle(
                        color: isDark ? Colors.blue[300] : Colors.blue[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy').format(article.publishedAt),
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
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
      ),
    );
  }
}
