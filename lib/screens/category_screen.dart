import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart';
import 'news_list_screen.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  
  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class CategoryScreen extends StatelessWidget {
  final NewsSource activeSource;
  const CategoryScreen({Key? key, required this.activeSource})
      : super(key: key);

  static const List<CategoryItem> _categoriesIndo = [
    CategoryItem(
      id: 'nasional',
      name: 'Nasional',
      icon: Icons.flag_rounded,
      color: Color(0xFF5F6368),
      description: 'Berita dalam negeri terkini',
    ),
    CategoryItem(
      id: 'teknologi',
      name: 'Teknologi',
      icon: Icons.devices_rounded,
      color: Color(0xFF6B7280),
      description: 'Tech, gadget & inovasi',
    ),
    CategoryItem(
      id: 'olahraga',
      name: 'Olahraga',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF4B5563),
      description: 'Update dunia olahraga',
    ),
    CategoryItem(
      id: 'bisnis',
      name: 'Bisnis',
      icon: Icons.business_center_rounded,
      color: Color(0xFF6B7280),
      description: 'Ekonomi & finansial',
    ),
    CategoryItem(
      id: 'hiburan',
      name: 'Hiburan',
      icon: Icons.theaters_rounded,
      color: Color(0xFF5F6368),
      description: 'Selebriti & entertainment',
    ),
    CategoryItem(
      id: 'kesehatan',
      name: 'Kesehatan',
      icon: Icons.favorite_rounded,
      color: Color(0xFF4B5563),
      description: 'Tips hidup sehat',
    ),
    CategoryItem(
      id: 'otomotif',
      name: 'Otomotif',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF6B7280),
      description: 'Mobil & motor terbaru',
    ),
    CategoryItem(
      id: 'lifestyle',
      name: 'Lifestyle',
      icon: Icons.diamond_rounded,
      color: Color(0xFF5F6368),
      description: 'Gaya hidup & trend',
    ),
  ];

  static const List<CategoryItem> _categoriesLuar = [
    CategoryItem(
      id: 'general',
      name: 'General',
      icon: Icons.public_rounded,
      color: Color(0xFF5F6368),
      description: 'Top headlines worldwide',
    ),
    CategoryItem(
      id: 'technology',
      name: 'Technology',
      icon: Icons.devices_rounded,
      color: Color(0xFF6B7280),
      description: 'Tech & innovation news',
    ),
    CategoryItem(
      id: 'sports',
      name: 'Sports',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF4B5563),
      description: 'Sports updates & scores',
    ),
    CategoryItem(
      id: 'business',
      name: 'Business',
      icon: Icons.business_center_rounded,
      color: Color(0xFF6B7280),
      description: 'Market & finance news',
    ),
    CategoryItem(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.theaters_rounded,
      color: Color(0xFF5F6368),
      description: 'Movies, music & celebs',
    ),
    CategoryItem(
      id: 'health',
      name: 'Health',
      icon: Icons.favorite_rounded,
      color: Color(0xFF4B5563),
      description: 'Wellness & health tips',
    ),
    CategoryItem(
      id: 'science',
      name: 'Science',
      icon: Icons.science_rounded,
      color: Color(0xFF6B7280),
      description: 'Scientific discoveries',
    ),
  ];

  void _navigateToNewsList(BuildContext context, String categoryId,
      String categoryName, NewsSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsListScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          source: source,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesToShow =
        activeSource == NewsSource.indo ? _categoriesIndo : _categoriesLuar;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              floating: true,
              elevation: 0,
              backgroundColor: const Color(0xFFF8F4EC),
              toolbarHeight: 80,
              automaticallyImplyLeading: false,
              flexibleSpace: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kategori Berita 📚',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4F4F4F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pilih kategori yang kamu suka',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFBDBDBD),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Category Cards - Grid Layout 2 Kolom
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categoriesToShow[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 80)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _CategoryCard(
                        item: category,
                        onTap: () => _navigateToNewsList(
                            context, category.id, category.name, activeSource),
                      ),
                    );
                  },
                  childCount: categoriesToShow.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color,
              item.color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with background
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Category info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
            
            // Arrow indicator
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}