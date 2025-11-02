import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors_new.dart';

class NewsHomeScreen extends StatefulWidget {
  const NewsHomeScreen({super.key});

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen> {
  int _selectedIndex = 0;
  String _selectedTab = 'Hari ini';

  final List<String> tabOptions = ['Hari ini', 'Populer', 'Terkini'];
  
  // Sample news categories with their colors
  final List<Map<String, dynamic>> newsCategories = [
    {
      'title': 'Teknologi',
      'description': '5 berita terbaru',
      'color': AppColors.cardYellow,
      'icon': Icons.computer_rounded,
      'count': 5,
    },
    {
      'title': 'Kesehatan',
      'description': '3 berita terbaru',
      'color': AppColors.cardGreen,
      'icon': Icons.health_and_safety_rounded,
      'count': 3,
    },
    {
      'title': 'Politik',
      'description': '7 berita terbaru',
      'color': AppColors.cardRed,
      'icon': Icons.how_to_vote_rounded,
      'count': 7,
    },
    {
      'title': 'Olahraga',
      'description': '4 berita terbaru',
      'color': AppColors.cardBlue,
      'icon': Icons.sports_soccer_rounded,
      'count': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: _buildMainContent(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        // Header with greeting and add button
        SliverAppBar(
          floating: true,
          elevation: 0,
          backgroundColor: AppColors.backgroundCream,
          toolbarHeight: 80,
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hai, Maftuh! 👋',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textGray,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Temukan berita terbaru hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tambah',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Category tabs
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabOptions.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.buttonBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppColors.softShadow,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                        ),
                        child: Text(
                          tab,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textGray,
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

        // News category cards grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= newsCategories.length) return null;
                
                final category = newsCategories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCategoryCard(
                    title: category['title'],
                    description: category['description'],
                    color: category['color'],
                    icon: category['icon'],
                    count: category['count'],
                  ),
                );
              },
              childCount: newsCategories.length,
            ),
          ),
        ),

        // Bottom spacing for navigation bar
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required int count,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to category detail
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigasi ke $title')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count+',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 8),

            // Description
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),

            SizedBox(height: 16),

            // Read more button or arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppColors.elevatedShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.category_rounded,
                label: 'Kategori',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.favorite_rounded,
                label: 'Favorit',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.buttonBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.buttonBlue : AppColors.textLight,
              size: 24,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.buttonBlue : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
