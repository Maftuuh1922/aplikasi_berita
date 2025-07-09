import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart';
import 'news_list_screen.dart';

class CategoryItem {
  final String id;
  final String name;
  final String icon;
  const CategoryItem({required this.id, required this.name, required this.icon});
}

class CategoryScreen extends StatelessWidget {
  final NewsSource activeSource;
  const CategoryScreen({Key? key, required this.activeSource}) : super(key: key);

  static const List<CategoryItem> _categoriesIndo = [
    CategoryItem(id: 'nasional', name: 'Nasional', icon: '🇮🇩'),
    CategoryItem(id: 'ekonomi', name: 'Ekonomi', icon: '💼'),
    CategoryItem(id: 'olahraga', name: 'Olahraga', icon: '⚽'),
    CategoryItem(id: 'teknologi', name: 'Teknologi', icon: '💻'),
  ];

  static const List<CategoryItem> _categoriesLuar = [
    CategoryItem(id: 'general', name: 'Terkini', icon: '⚡'),
    CategoryItem(id: 'world', name: 'Dunia', icon: '🌍'),
    CategoryItem(id: 'business', name: 'Bisnis', icon: '💼'),
    CategoryItem(id: 'sports', name: 'Olahraga', icon: '🏅'),
  ];

  void _navigateToNewsList(BuildContext context, String categoryId, String categoryName, NewsSource source) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesToShow = activeSource == NewsSource.indo ? _categoriesIndo : _categoriesLuar;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea( // Add SafeArea to prevent system UI cutoff
        child: CustomScrollView(
          slivers: [
            // App Bar with proper safe area handling
            SliverAppBar(
              expandedHeight: 100, // Reduced height
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                        ? [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.grey[900]!.withValues(alpha: 0.8),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.8),
                            Colors.grey[50]!.withValues(alpha: 0.9),
                          ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Jelajahi Kategori',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 18, // Slightly smaller font
                    ),
                  ),
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16), // Add padding
                ),
              ),
            ),

            // Category Grid with proper padding to prevent cutoff
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // Extra bottom padding for navigation
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1, // Adjusted ratio for better fit
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categoriesToShow[index];
                    return _CategoryCard(
                      item: category,
                      isDark: isDark,
                      index: index,
                      onTap: () => _navigateToNewsList(context, category.id, category.name, activeSource),
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
  final bool isDark;
  final int index;
  final VoidCallback onTap;
  
  const _CategoryCard({
    required this.item,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors(index);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.all(2), // Small margin to prevent edge cutoff
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.grey[900]!.withValues(alpha: 0.6),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9), // More opaque
                      Colors.grey[50]!.withValues(alpha: 0.95),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08), // More visible
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.25), // Enhanced shadow
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors[0].withValues(alpha: 0.1),
                      gradientColors[1].withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              
              // Content with safe padding
              Padding(
                padding: const EdgeInsets.all(12), // Padding to prevent content cutoff
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14), // Slightly smaller padding
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 26), // Slightly smaller emoji
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Smaller font to prevent cutoff
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
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

  List<Color> _getGradientColors(int index) {
    const colors = [
      [Colors.blue, Colors.cyan],
      [Colors.purple, Colors.pink],
      [Colors.orange, Colors.red],
      [Colors.green, Colors.teal],
      [Colors.indigo, Colors.blue],
      [Colors.amber, Colors.orange],
    ];
    return [colors[index % colors.length][0], colors[index % colors.length][1]];
  }
}