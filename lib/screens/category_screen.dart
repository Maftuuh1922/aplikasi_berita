// Full Revisi CategoryScreen dengan fix overflow, scroll, dan UI clean
import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  final List<String> _filterTags = [
    'Semua',
    'Trending',
    'Terbaru',
    'Terpopuler',
    'Favorit'
  ];

  final List<CategoryItem> _mainCategories = [
    CategoryItem(
      name: 'Politik',
      icon: '🏛️',
      articleCount: 142,
      color: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      id: 'politik',
    ),
    CategoryItem(
      name: 'Bisnis',
      icon: '💼',
      articleCount: 89,
      color: const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF7FDBDA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      id: 'bisnis',
    ),
  ];

  final List<TrendingItem> _trendingCategories = [
    TrendingItem(rank: 1, name: 'Ekonomi', newArticles: 24, id: 'ekonomi'),
    TrendingItem(rank: 2, name: 'Internasional', newArticles: 18, id: 'internasional'),
    TrendingItem(rank: 3, name: 'Hukum', newArticles: 12, id: 'hukum'),
    TrendingItem(rank: 4, name: 'Lingkungan', newArticles: 9, id: 'lingkungan'),
    TrendingItem(rank: 5, name: 'Otomotif', newArticles: 7, id: 'otomotif'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F4),
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HAPUS: _buildHeader(),
                // HAPUS: _buildSearchSection(),
                _buildFilterTags(),
                const SizedBox(height: 20),
                _buildCategoriesContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTags() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = _filterTags[index];
          final isActive = tag == _selectedFilter;
          return GestureDetector(
            onTap: () => _selectFilter(tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF667eea) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tag, style: TextStyle(color: isActive ? Colors.white : Colors.black)),
            ),
          );
        },
      ),
    );
  }

// Ubah _buildCategoriesContent agar tidak ada padding lagi (karena sudah di luar)
  Widget _buildCategoriesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _mainCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final category = _mainCategories[index];
            return GestureDetector(
              onTap: () => _selectCategory(category.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: category.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(category.icon, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(height: 12),
                    Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${category.articleCount} artikel', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        const Text('Trending Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(children: _trendingCategories.map(_buildTrendingItem).toList()),
        const SizedBox(height: kBottomNavigationBarHeight + 16),
      ],
    );
  }

  Widget _buildTrendingItem(TrendingItem item) {
    return GestureDetector(
      onTap: () => _selectCategory(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF667eea),
              child: Text('${item.rank}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${item.newArticles} artikel baru', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Text('🔥'),
          ],
        ),
      ),
    );
  }

  void _goBack() => Navigator.pop(context);
  void _selectFilter(String tag) => setState(() => _selectedFilter = tag);
  void _searchCategories(String query) => print('Searching: \$query');
  void _selectCategory(String id) => print('Category selected: \$id');
  void _navigateTo(int index) => print('Navigate to \$index');
}

class CategoryItem {
  final String name, icon, id;
  final int articleCount;
  final LinearGradient color;
  CategoryItem({required this.name, required this.icon, required this.articleCount, required this.color, required this.id});
}

class TrendingItem {
  final int rank, newArticles;
  final String name, id;
  TrendingItem({required this.rank, required this.name, required this.newArticles, required this.id});
}
