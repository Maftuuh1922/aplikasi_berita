import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../main.dart'; // Mengasumsikan ini berisi enum NewsSource
import '../models/article.dart';
import '../services/news_api_service.dart'; // Untuk berita internasional (GNews)
import '../services/berita_indo_api_service.dart'; // Untuk berita Indonesia
import '../utils/layout_metrics.dart';
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
  Timer? _debounceTimer; // For search debouncing

  List<Article> _articles = [];
  List<Article> _trendingArticles = [];
  List<Article> _filteredArticles = []; // Cache filtered articles
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
    {'key': 'sports', 'name': 'Olahraga'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
    _setupScrollListener();
    _searchController.addListener(() {
      // Debounce search to avoid frequent rebuilds
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
            _updateFilteredArticles();
          });
        }
      });
    });

    // Tambahkan focus listener
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  // Helper method to update filtered articles
  void _updateFilteredArticles() {
    if (_searchQuery.isEmpty) {
      _filteredArticles = _articles;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredArticles = _articles
          .where((a) => a.title.toLowerCase().contains(query))
          .toList();
    }
  }

  // Setup scroll listener to hide/show trending and categories
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 200) {
        // Hide trending jika tidak sedang search dan search tidak fokus
        if (_showTrendingAndCategories &&
            _searchQuery.isEmpty &&
            !_isSearchFocused) {
          setState(() => _showTrendingAndCategories = false);
        }
        if (_showSearchBar) {
          setState(() => _showSearchBar = false);
          _searchFocusNode.unfocus();
        }
      } else if (_scrollController.offset <= 200) {
        if (!_showTrendingAndCategories &&
            _searchQuery.isEmpty &&
            !_isSearchFocused) {
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
    _debounceTimer?.cancel();
    _pageController.dispose();
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
          _updateFilteredArticles(); // Update filtered list
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
    setState(() {
      _selectedCategory = apiCategory;
      _articles = []; // Clear untuk loading state
      _filteredArticles = [];
    });
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
      _filteredArticles = [];
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
      backgroundColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // avoid horizontal gesture jank
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        itemCount: 4,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _buildHomePage();
            case 1:
              return CategoryScreen(activeSource: _selectedSource);
            case 2:
              return const BookmarksScreen();
            case 3:
            default:
              return const ProfileScreen();
          }
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: _selectedIndex == 0
                    ? Icons.home_rounded
                    : Icons.home_outlined,
                isSelected: _selectedIndex == 0,
                onTap: () => _onNavTapped(0),
              ),
              _buildNavItem(
                icon: _selectedIndex == 1
                    ? Icons.dashboard_rounded
                    : Icons.dashboard_outlined,
                isSelected: _selectedIndex == 1,
                onTap: () => _onNavTapped(1),
              ),
              _buildNavItem(
                icon: _selectedIndex == 2
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                isSelected: _selectedIndex == 2,
                onTap: () => _onNavTapped(2),
              ),
              _buildNavItem(
                icon: _selectedIndex == 3
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
                isSelected: _selectedIndex == 3,
                onTap: () => _onNavTapped(3),
              ),
            ],
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
      splashColor:
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
        color: isSelected
          ? (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
            .withValues(alpha: 0.2)
          : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: isSelected
                  ? Border.all(
                      color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                      width: 1.5,
                    )
                  : null,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
          color: isSelected
            ? (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
              .withValues(alpha: 0.2)
            : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
                      : (isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E)), // Gray
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
    final layout = LayoutMetrics.of(context);
    // Use cached filtered articles instead of calculating every build
    final articlesToShow = _filteredArticles;
    final showDiscover =
        _showTrendingAndCategories && _searchQuery.isEmpty && !_isSearchFocused;

    final ScrollPhysics physics = Theme.of(context).platform == TargetPlatform.iOS
        ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
        : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thickness: MaterialStateProperty.all(10),
        radius: const Radius.circular(12),
        thumbVisibility: MaterialStateProperty.all(true),
        trackVisibility: MaterialStateProperty.all(true),
        thumbColor: MaterialStateProperty.all(
          isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
        ),
        trackColor: MaterialStateProperty.all(
          isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
        ),
      ),
      child: Scrollbar(
        controller: _scrollController,
        interactive: true,
        thumbVisibility: true,
        thickness: 10,
        radius: const Radius.circular(12),
        child: CustomScrollView(
          controller: _scrollController,
          physics: physics,
          cacheExtent: 1000, // Increase cache for smoother scrolling
          slivers: [
        // Dynamic Header
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          expandedHeight: layout.largeGap * 4.5,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.horizontal,
                  vertical: layout.smallGap,
                ),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.smallGap * 1.2,
                          vertical: layout.smallGap * 0.6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
                          borderRadius:
                              BorderRadius.circular(layout.cardRadius * 0.75),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'FOKUS',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                            if (!_showSearchBar) ...[
                              SizedBox(width: layout.smallGap * 0.8),
                              Icon(
                                Icons.search_rounded,
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Ganti bagian dropdown bendera dalam _buildHomePage() dengan ini:
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.smallGap,
                        vertical: layout.smallGap * 0.6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
                        borderRadius: BorderRadius.circular(layout.cardRadius),
                        border: Border.all(
                          color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<NewsSource>(
                          value: _selectedSource,
                          onChanged: _onSourceChanged,
                          dropdownColor:
                              isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
                          items: [
                            DropdownMenuItem(
                              value: NewsSource.indo,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(width: layout.smallGap * 0.8),
                                  Text(
                                    'ID',
                                    style: TextStyle(
                                      fontSize: layout.scaledFont(11),
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFFFEB3B) // Yellow
                                          : const Color(0xFFFFEB3B), // Yellow
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
                                    width: 22,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: Colors.blue,
                                    ),
                                    child: const Icon(Icons.public_rounded,
                                        size: 10, color: Colors.white),
                                  ),
                                  SizedBox(width: layout.smallGap * 0.8),
                                  Text(
                                    'EN',
                                    style: TextStyle(
                                      fontSize: layout.scaledFont(11),
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF9E9E9E) // Gray
                                          : const Color(0xFF9E9E9E), // Gray
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                          ),
                          style: TextStyle(
                              color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)), // Yellow
                        ),
                      ),
                    ),
                  ],
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
              margin: EdgeInsets.fromLTRB(
                layout.horizontal,
                0,
                layout.horizontal,
                layout.smallGap,
              ),
              child: Container(
                padding: EdgeInsets.all(layout.smallGap * 1.1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
                  borderRadius: BorderRadius.circular(layout.cardRadius),
                  border: Border.all(
                    color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari berita...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      fontSize: layout.scaledFont(14),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      size: layout.scaledFont(20),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[500],
                              size: layout.scaledFont(20),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(layout.cardRadius),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(layout.cardRadius),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: layout.smallGap * 1.6,
                      vertical: layout.smallGap,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Enhanced Trending Section with smooth show/hide
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: showDiscover
                ? Container(
                    key: const ValueKey('trending_shown'),
                    margin: EdgeInsets.fromLTRB(
                      layout.horizontal,
                      layout.smallGap,
                      layout.horizontal,
                      layout.mediumGap,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(layout.mediumGap * 1.2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1), // Cream background
                        borderRadius:
                            BorderRadius.circular(layout.cardRadius * 1.2),
                        border: Border.all(
                          color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(layout.smallGap),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2196F3) : const Color(0xFF1976D2), // Solid blue color instead of gradient
                                  borderRadius: BorderRadius.circular(layout.cardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark ? const Color(0xFF2196F3) : const Color(0xFF1976D2))
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.trending_up_rounded,
                                  color: Colors.white,
                                  size: layout.scaledFont(20),
                                ),
                              ),
                              SizedBox(width: layout.mediumGap * 0.9),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: layout.smallGap,
                                  vertical: layout.smallGap * 0.3,
                                ),
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(layout.smallGap),
                                ),
                                child: Text(
                                  'Trending',
                                  style: TextStyle(
                                    fontSize: layout.scaledFont(20),
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: layout.mediumGap * 1.1),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_trendingArticles.isNotEmpty)
                            _TrendingCard(
                                article: _trendingArticles.first,
                                isDark: isDark)
                          else
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(
                                    layout.cardRadius),
                              ),
                              child: Center(
                                child: Text(
                                  'Tidak ada berita trending',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('trending_hidden')),
          ),
        ),

        // Enhanced Category Chips with smooth show/hide
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: showDiscover
                ? Container(
                    key: const ValueKey('chips_shown'),
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontal,
                      0,
                      layout.horizontal,
                      layout.mediumGap,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.smallGap * 1.2,
                            vertical: layout.smallGap * 0.6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C), // Solid green color instead of gradient
                            borderRadius: BorderRadius.circular(layout.cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C))
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(layout.smallGap * 0.4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(layout.smallGap * 0.7),
                                ),
                                child: Icon(
                                  Icons.article_rounded,
                                  color: Colors.white,
                                  size: layout.scaledFont(16),
                                ),
                              ),
                              SizedBox(width: layout.smallGap * 0.8),
                              Text(
                                'Berita Terbaru',
                                style: TextStyle(
                                  fontSize: layout.scaledFont(20),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: layout.mediumGap),
                        SizedBox(
                          height: layout.mediumGap * 3.4,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: EdgeInsets.zero,
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
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('chips_hidden')),
          ),
        ),

        // Enhanced News List
        if (_isLoading && _articles.isEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40.0), // Increased padding for better spacing
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_errorMessage != null)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30), // Increased padding for better spacing
                child: Column(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 72, // Larger icon
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E)), // Gray
                    const SizedBox(height: 20), // Increased spacing
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, // Larger font
                          color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575)), // Better color
                    ),
                    const SizedBox(height: 20), // Increased spacing
                    ElevatedButton(
                      onPressed: _loadNews,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B), // Yellow
                        foregroundColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFF2E2E2E), // Dark text on yellow
                        padding: EdgeInsets.symmetric(
                          horizontal: 24, // More horizontal padding
                          vertical: 12, // More vertical padding
                        ),
                      ),
                      child: const Text('Coba Lagi',
                        style: TextStyle(fontSize: 16), // Larger font
                      ),
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
                if (index >= articlesToShow.length) return null;
                final layout = LayoutMetrics.of(context);
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontal,
                    vertical: layout.smallGap, // Increased vertical spacing for better readability
                  ),
                  child: _NewsListItem(
                    key: ValueKey('news_${articlesToShow[index].url}'),
                    article: articlesToShow[index],
                    onTap: () =>
                        _navigateToArticle(context, articlesToShow[index]),
                    isDark: isDark,
                  ),
                );
              },
              childCount: articlesToShow.length,
              addAutomaticKeepAlives: false, // Disable to reduce memory
              addRepaintBoundaries: true,
              addSemanticIndexes: false, // Disable for performance
            ),
          ),

        // Bottom padding for navigation
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Article article;
  final bool isDark;
  const _TrendingCard({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final layout = LayoutMetrics.of(context);
    final backgroundColor = isDark 
        ? const Color(0xFF2E2E2E) // Dark card background (cream variant)
        : const Color(0xFFFFF8E1); // Light card background (cream)
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(layout.cardRadius * 1.8),
      elevation: 0,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ArticleWebviewScreen(article: article),
          ),
        ),
        borderRadius: BorderRadius.circular(layout.cardRadius * 1.8),
        child: Container(
          height: layout.mediumGap * 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.cardRadius * 1.8),
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey[400]!)
                    .withValues(alpha: isDark ? 0.5 : 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark 
                  ? const Color(0xFFFFEB3B).withValues(alpha: 0.3) // Yellow
                  : const Color(0xFFFFEB3B).withValues(alpha: 0.5), // Yellow
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(layout.cardRadius * 1.8),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                      ? Image.network(
                          article.urlToImage!,
                          fit: BoxFit.cover,
                          cacheWidth: 400,
                          cacheHeight: 300,
                          filterQuality: FilterQuality.low,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: isDark 
                                  ? const Color(0xFF2E2E2E) // Dark loading background (cream variant)
                                  : const Color(0xFFFFF8E1), // Light loading background (cream)
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(layout.smallGap),
                                  decoration: BoxDecoration(
                                    color: (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
                                        .withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFF9E9E9E), // Yellow/Gray
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark 
                                ? const Color(0xFF2E2E2E) // Dark error background (cream variant)
                                : const Color(0xFFFFF8E1), // Light error background (cream)
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(layout.smallGap * 1.5),
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.image_rounded,
                                  size: layout.scaledFont(36),
                                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: isDark 
                              ? const Color(0xFF2E2E2E) // Dark fallback background (cream variant)
                              : const Color(0xFFFFF8E1), // Light fallback background (cream)
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(layout.smallGap * 1.5),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.article_rounded,
                                size: layout.scaledFont(36),
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                              ),
                            ),
                          ),
                        ),
                ),
                // Dark overlay for better text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Premium trending badge with solid color
                Positioned(
                  top: layout.smallGap * 1.2,
                  left: layout.smallGap * 1.2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.smallGap * 1.2,
                      vertical: layout.smallGap * 0.6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F), // Solid red color instead of gradient
                      borderRadius: BorderRadius.circular(layout.smallGap * 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: layout.scaledFont(14),
                        ),
                        SizedBox(width: layout.smallGap * 0.4),
                        Text(
                          'TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: layout.scaledFont(10),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content overlay with solid color
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(layout.smallGap * 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source with premium styling
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.smallGap * 1.2, // Increased padding
                            vertical: layout.smallGap * 0.5, // Increased padding
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25), // Increased contrast
                            borderRadius: BorderRadius.circular(layout.smallGap * 1.2), // Slightly more rounded
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35), // Increased contrast
                              width: 0.7, // Slightly thicker border
                            ),
                          ),
                          child: Text(
                            article.sourceName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: layout.scaledFont(11.5), // Slightly larger font
                              fontWeight: FontWeight.w700, // Increased weight
                              letterSpacing: 0.35, // Slightly more spacing
                            ),
                          ),
                        ),
                        SizedBox(height: layout.smallGap * 1.2), // Increased spacing
                        // Title with enhanced typography
                        Text(
                          article.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: layout.scaledFont(19.5), // Increased font size
                            fontWeight: FontWeight.w700, // Reduced from w800 for better readability
                            height: 1.5, // Increased line height for readability
                            letterSpacing: 0.15, // More positive letter spacing
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: layout.smallGap * 1.1), // Increased spacing
                        // Date with icon
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(layout.smallGap * 0.35), // Increased padding
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3), // Increased contrast
                                borderRadius: BorderRadius.circular(layout.smallGap * 0.8), // Slightly more rounded
                              ),
                              child: Icon(
                                Icons.schedule_rounded,
                                size: layout.scaledFont(12.5), // Slightly larger icon
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: layout.smallGap * 0.9), // Increased spacing
                            Text(
                              DateFormat('d MMM yyyy').format(article.publishedAt),
                              style: TextStyle(
                                color: Colors.white, // Increased contrast by removing alpha
                                fontSize: layout.scaledFont(12.5), // Slightly larger font
                                fontWeight: FontWeight.w600, // Increased weight for better visibility
                                letterSpacing: 0.35, // Slightly more spacing
                              ),
                            ),
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
    final layout = LayoutMetrics.of(context);
    final selectedColor = isDark 
        ? const Color(0xFFFFEB3B) // Dark theme yellow
        : const Color(0xFFFFEB3B); // Light theme yellow
    final unselectedColor = isDark 
        ? const Color(0xFF2E2E2E) // Dark theme background (cream variant)
        : const Color(0xFFFFF8E1); // Light theme background (cream)
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(layout.cardRadius * 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius * 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(right: layout.smallGap * 1.2),
          padding: EdgeInsets.symmetric(
            horizontal: layout.smallGap * 1.8,
            vertical: layout.smallGap * 1,
          ),
          constraints: BoxConstraints(
            minHeight: layout.mediumGap * 2.4,
            maxHeight: layout.mediumGap * 2.4,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(layout.cardRadius * 2),
            border: Border.all(
              color: isSelected
                  ? selectedColor // Use the same color as background for selected to create a border effect
                  : (isDark ? const Color(0xFFFFEB3B).withValues(alpha: 0.3) : const Color(0xFFFFEB3B).withValues(alpha: 0.5)), // Yellow border
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E)) // Gray
                          .withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Container(
                    padding: EdgeInsets.all(layout.smallGap * 0.25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E).withValues(alpha: 0.3), // Dark color with transparency
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: const Color(0xFF2E2E2E), // Dark color for icon on yellow background
                      size: layout.scaledFont(12),
                    ),
                  ),
                  SizedBox(width: layout.smallGap * 0.6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF2E2E2E) // Dark text on yellow background
                        : (isDark ? const Color(0xFFFFEB3B) : const Color(0xFF9E9E9E)), // Yellow or gray text
                    fontSize: layout.scaledFont(13),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
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
  final bool isDark;

  const _NewsListItem({
    super.key,
    required this.article,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final layout = LayoutMetrics.of(context);
    final cardColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1); // Solid card background (cream)
    final imagePlaceholderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF8E1); // Solid placeholder color (cream)
    final sourceBackgroundColor = isDark 
        ? const Color(0xFFFFEB3B).withValues(alpha: 0.2) // Yellow with transparency on dark theme
        : const Color(0xFFFFEB3B).withValues(alpha: 0.15); // Yellow with transparency on light theme
    final sourceTextColor = isDark ? const Color(0xFFFFEB3B) : const Color(0xFF9E9E9E); // Yellow or gray text color
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(layout.cardRadius * 1.2),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius * 1.2),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: layout.smallGap * 0.7),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(layout.cardRadius * 1.2),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E)) // Gray
                    .withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark 
                  ? const Color(0xFFFFEB3B).withValues(alpha: 0.2) // Yellow
                  : const Color(0xFFFFEB3B).withValues(alpha: 0.3), // Yellow
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(layout.cardRadius * 1.2),
            child: Row(
              children: [
                // Enhanced Image Container with solid color
                Container(
                  width: layout.mediumGap * 5.5,
                  height: layout.mediumGap * 5.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(layout.cardRadius * 1.2),
                      bottomLeft: Radius.circular(layout.cardRadius * 1.2),
                    ),
                    color: imagePlaceholderColor, // Solid color instead of gradient
                  ),
                  child: Stack(
                    children: [
                      if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            article.urlToImage!,
                            fit: BoxFit.cover,
                            cacheWidth: 150,
                            cacheHeight: 150,
                            filterQuality: FilterQuality.low,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: child,
                              );
                            },
                            errorBuilder: (c, e, s) => Container(
                              color: imagePlaceholderColor, // Solid color instead of gradient
                              child: Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                                  size: layout.scaledFont(28),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Subtle overlay for better text readability using solid color with transparency
                      if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  (isDark ? const Color(0xFFFFF8E1) : const Color(0xFF2E2E2E)) // Cream or dark
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Fallback icon when no image
                      if (article.urlToImage == null || article.urlToImage!.isEmpty)
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(layout.smallGap),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.article_rounded,
                              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                              size: layout.scaledFont(24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Enhanced Content with better spacing
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(layout.smallGap * 1.6), // Increased padding for more breathing space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Source with accent color using solid color
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.smallGap,
                            vertical: layout.smallGap * 0.4, // Increased padding
                          ),
                          decoration: BoxDecoration(
                            color: sourceBackgroundColor,
                            borderRadius: BorderRadius.circular(layout.smallGap * 1.2), // Slightly more rounded
                          ),
                          child: Text(
                            article.sourceName,
                            style: TextStyle(
                              color: sourceTextColor,
                              fontSize: layout.scaledFont(10.5), // Slightly larger font
                              fontWeight: FontWeight.w700, // Increased weight for better visibility
                              letterSpacing: 0.35, // Slightly more spacing
                            ),
                          ),
                        ),
                        SizedBox(height: layout.smallGap), // Increased spacing
                        // Title with better typography
                        Text(
                          article.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, // Reduced from w700 for better readability
                            fontSize: layout.scaledFont(16.5), // Increased font size
                            color: isDark ? const Color(0xFFFFEB3B) : const Color(0xFF9E9E9E), // Yellow or gray color
                            height: 1.45, // Increased line height for readability
                            letterSpacing: 0.25, // More positive letter spacing for readability
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: layout.smallGap), // Increased spacing
                        // Date with icon
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(layout.smallGap * 0.3), // Increased padding
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFFFFEB3B) : const Color(0xFFFFEB3B)) // Yellow
                                    .withValues(alpha: 0.2), // Increased contrast
                                borderRadius: BorderRadius.circular(layout.smallGap * 0.6), // Slightly more rounded
                              ),
                              child: Icon(
                                Icons.schedule_rounded,
                                size: layout.scaledFont(11.5), // Slightly larger icon
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                              ),
                            ),
                            SizedBox(width: layout.smallGap * 0.7), // Increased spacing
                            Text(
                              DateFormat('d MMM yyyy').format(article.publishedAt),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E), // Gray
                                fontSize: layout.scaledFont(11.5), // Slightly larger font
                                fontWeight: FontWeight.w600, // Increased weight for better visibility
                                letterSpacing: 0.25, // Slightly more spacing
                              ),
                            ),
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
      ),
    );
  }
}
