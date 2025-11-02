import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article.dart';
import '../services/news_api_service.dart';
import '../services/berita_indo_api_service.dart';
import '../main.dart';
import 'article_detail_screen.dart';
import 'category_screen.dart';
import 'bookmarks_screen.dart';
import 'profile_screen.dart';
import '../utils/app_colors_new.dart' as AppColorsLib;

/// Enhanced version of news_home_screen.dart dengan integrasi API
/// File ini menunjukkan cara menggunakan data asli dari aplikasi

class NewsHomeScreenWithAPI extends StatefulWidget {
  const NewsHomeScreenWithAPI({super.key});

  @override
  State<NewsHomeScreenWithAPI> createState() => _NewsHomeScreenWithAPIState();
}

class _NewsHomeScreenWithAPIState extends State<NewsHomeScreenWithAPI> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  PageController? _pageController;
  AnimationController? _animationController;
  
  // Pages list
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize cached pages once
    _pages = [
      const _HomeContentPage(),
      const CategoryScreen(activeSource: NewsSource.indo),
      const BookmarksScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      extendBody: true,
      body: PageView.builder(
        controller: _pageController ?? PageController(),
        physics: const BouncingScrollPhysics(), // Smooth swipe
        onPageChanged: (index) {
          if (mounted) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return _pages[index];
        },
      ),
      floatingActionButton: _buildFloatingNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Floating Navigation Bar yang melayang
  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF5F6368).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingNavItem(Icons.home_rounded, 'Beranda', 0),
          _buildFloatingNavItem(Icons.grid_view_rounded, 'Kategori', 1),
          _buildFloatingNavItem(Icons.bookmark_rounded, 'Favorit', 2),
          _buildFloatingNavItem(Icons.person_rounded, 'Profil', 3),
        ],
      ),
    );
  }

  Widget _buildFloatingNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController?.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
        _animationController?.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5F6368)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFFBDBDBD),
              size: isSelected ? 24 : 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Separate StatefulWidget for Home Content with caching
class _HomeContentPage extends StatefulWidget {
  const _HomeContentPage({Key? key}) : super(key: key);

  @override
  State<_HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<_HomeContentPage> with AutomaticKeepAliveClientMixin {
  String _selectedTab = 'Hari ini';
  final NewsSource _selectedSource = NewsSource.indo;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final List<String> tabOptions = ['Hari ini', 'Populer', 'Terkini'];
  Future<List<Article>>? _futureArticles;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  // Get user name from Firebase Auth
  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Jika ada displayName, gunakan itu
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      }
      // Jika tidak ada displayName, ambil dari email (bagian sebelum @)
      if (user.email != null && user.email!.isNotEmpty) {
        return user.email!.split('@')[0];
      }
      // Jika anonymous user
      if (user.isAnonymous) {
        return 'Tamu';
      }
    }
    // Default jika tidak ada user
    return 'Pengguna';
  }

  void _loadArticles() {
    setState(() {
      _futureArticles = _selectedSource == NewsSource.indo
          ? BeritaIndoApiService().fetchNews(category: 'nasional')
          : NewsApiService().fetchNews(category: 'general');
    });
  }

  Future<void> _handleRefresh() async {
    _loadArticles();
    await _futureArticles;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  bool _isNewArticle(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inHours < 24;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF5F6368),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header (Simplified)
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: const Color(0xFFF8F4EC),
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4EC),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Greeting
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hai, ${_getUserName()}! 👋',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4F4F4F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Temukan berita terbaru hari ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFBDBDBD),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari berita...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFBDBDBD),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: const Color(0xFF5F6368),
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: const Color(0xFFBDBDBD),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: tabOptions.map((tab) {
                    final isSelected = _selectedTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = tab;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5F6368)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4F4F4F),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Stats Card with Animation
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (value * 0.1),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildStatsCard(),
              ),
            ),
          ),

          // Trending + News List
          SliverToBoxAdapter(
            child: FutureBuilder<List<Article>>(
              future: _futureArticles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: [
                      _buildTrendingSkeleton(),
                      _buildNewsSkeleton(),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Oops! Terjadi Kesalahan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4F4F4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final articles = snapshot.data ?? [];
                final filteredArticles = _searchQuery.isEmpty
                    ? articles
                    : articles.where((article) {
                        return article.title.toLowerCase().contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filteredArticles.isEmpty) {
                  return _buildEmptyState();
                }

                final trendingArticles = filteredArticles.take(5).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trending Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: const Color(0xFF6B7280),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trending Sekarang 🔥',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4F4F4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trendingArticles.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildTrendingCard(trendingArticles[index], index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Semua Berita Label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.article_rounded,
                            color: const Color(0xFF5F6368),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Semua Berita',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4F4F4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // News List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredArticles.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildNewsListItem(filteredArticles[index]),
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Space for floating nav
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton Loading untuk Trending
  Widget _buildTrendingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 24,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Skeleton Loading untuk News List
  Widget _buildNewsSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Empty State ketika search tidak ada hasil
  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4F4F4F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci lain',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }

  // Empty State ketika tidak ada berita
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada berita',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4F4F4F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tarik ke bawah untuk memuat ulang',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }

  // Stats Card untuk menampilkan info tambahan
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5F6368),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5F6368).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.article_rounded, '120+', 'Artikel'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem(Icons.update_rounded, 'Hari ini', 'Update'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem(Icons.language_rounded, '5+', 'Sumber'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsListItem(Article article) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: AppColorsLib.AppColors.textLight.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail (Optimized Size)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                  child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                      ? Image.network(
                          article.urlToImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.image_rounded,
                              color: AppColorsLib.AppColors.textLight,
                              size: 44,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.article_rounded,
                            color: AppColorsLib.AppColors.textLight,
                            size: 44,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              // Source Badge & New Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.sourceName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  if (_isNewArticle(article.publishedAt)) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7280).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fiber_new_rounded,
                            size: 13,
                            color: const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Baru',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColorsLib.AppColors.textGray,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              // Date & Read Time
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColorsLib.AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(article.publishedAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColorsLib.AppColors.textLight,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.remove_red_eye_outlined,
                    size: 14,
                    color: AppColorsLib.AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '5 min baca',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColorsLib.AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard(Article article, int index) {
    // Warna abu-abu untuk semua trending card
    final colors = [
      const Color(0xFF6B7280), // Gray 500
      const Color(0xFF4B5563), // Gray 600
      const Color(0xFF374151), // Gray 700
      const Color(0xFF6B7280), // Gray 500
      const Color(0xFF4B5563), // Gray 600
    ];
    final color = colors[index % colors.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.85 + (value * 0.15),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Image
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.3),
                  child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                      ? Opacity(
                          opacity: 0.4,
                          child: Image.network(
                            article.urlToImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              // Content
              Container(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ranking Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '#${index + 1} Trending',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Title
                    Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Source
                  Text(
                    article.sourceName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
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
