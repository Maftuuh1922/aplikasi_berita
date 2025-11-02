import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_components.dart';

/// Contoh penggunaan AppComponents untuk membuat halaman berbeda
/// Gunakan sebagai referensi atau template untuk screen lain

class ComponentShowcaseScreen extends StatefulWidget {
  const ComponentShowcaseScreen({super.key});

  @override
  State<ComponentShowcaseScreen> createState() => _ComponentShowcaseScreenState();
}

class _ComponentShowcaseScreenState extends State<ComponentShowcaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      appBar: AppBar(
        title: AppComponents.headingText('Component Showcase'),
        backgroundColor: const Color(0xFFF8F4EC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ BUTTONS SECTION ============
            _buildSectionTitle('Buttons'),
            const SizedBox(height: 12),
            AppComponents.primaryButton(
              label: 'Primary Button',
              icon: Icons.check_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Primary button tapped')),
                );
              },
            ),
            const SizedBox(height: 12),
            AppComponents.secondaryButton(
              label: 'Secondary Button',
              icon: Icons.info_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secondary button tapped')),
                );
              },
            ),
            const SizedBox(height: 32),

            // ============ CATEGORY CARDS SECTION ============
            _buildSectionTitle('Category Cards'),
            const SizedBox(height: 12),
            AppComponents.categoryCard(
              title: 'Teknologi',
              description: '5 berita terbaru tentang teknologi',
              backgroundColor: const Color(0xFFF8D47E),
              icon: Icons.computer_rounded,
              count: '5+',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teknologi card tapped')),
                );
              },
            ),
            const SizedBox(height: 12),
            AppComponents.categoryCard(
              title: 'Kesehatan',
              description: '3 berita terbaru tentang kesehatan',
              backgroundColor: const Color(0xFF6FCF97),
              icon: Icons.health_and_safety_rounded,
              count: '3+',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kesehatan card tapped')),
                );
              },
            ),
            const SizedBox(height: 32),

            // ============ CHIPS SECTION ============
            _buildSectionTitle('Category Chips'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppComponents.categoryChip(
                  label: 'Hari ini',
                  isActive: _selectedTab == 0,
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                ),
                AppComponents.categoryChip(
                  label: 'Populer',
                  isActive: _selectedTab == 1,
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                ),
                AppComponents.categoryChip(
                  label: 'Terkini',
                  isActive: _selectedTab == 2,
                  onTap: () {
                    setState(() {
                      _selectedTab = 2;
                    });
                  },
                ),
                AppComponents.categoryChip(
                  label: 'Trending',
                  isActive: _selectedTab == 3,
                  onTap: () {
                    setState(() {
                      _selectedTab = 3;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ============ TEXT FIELDS SECTION ============
            _buildSectionTitle('Text Fields'),
            const SizedBox(height: 12),
            AppComponents.customTextField(
              hintText: 'Cari berita...',
              controller: _searchController,
              prefixIcon: Icons.search_rounded,
              suffixIcon: Icons.clear_rounded,
              onSuffixTap: () {
                _searchController.clear();
              },
            ),
            const SizedBox(height: 12),
            AppComponents.customTextField(
              hintText: 'Tulis komentar...',
              controller: TextEditingController(),
              maxLines: 3,
              prefixIcon: Icons.comment_rounded,
            ),
            const SizedBox(height: 32),

            // ============ TEXT STYLES SECTION ============
            _buildSectionTitle('Text Styles'),
            const SizedBox(height: 12),
            AppComponents.headingText('Heading Text (24px)'),
            const SizedBox(height: 8),
            AppComponents.bodyText('Body Text (14px) - Ini adalah contoh body text dengan style dan color yang konsisten'),
            const SizedBox(height: 8),
            AppComponents.labelText('Label Text (12px)'),
            const SizedBox(height: 32),

            // ============ ARTICLE CARDS SECTION ============
            _buildSectionTitle('Article Cards'),
            const SizedBox(height: 12),
            AppComponents.articleCard(
              title: 'Flutter 3.0 Diluncurkan dengan Fitur Baru',
              subtitle: 'Peningkatan performa hingga 50%',
              date: '2 Nov 2024',
              backgroundColor: const Color(0xFFFFF8F0),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article card 1 tapped')),
                );
              },
            ),
            const SizedBox(height: 8),
            AppComponents.articleCard(
              title: 'Cara Mengoptimalkan Performa Aplikasi',
              subtitle: 'Tips dan trik dari developer berpengalaman',
              date: '1 Nov 2024',
              backgroundColor: const Color(0xFFF0F8FF),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article card 2 tapped')),
                );
              },
            ),
            const SizedBox(height: 32),

            // ============ NAVIGATION ITEMS SECTION ============
            _buildSectionTitle('Navigation Items'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AppComponents.bottomNavItem(
                    icon: Icons.home_rounded,
                    label: 'Beranda',
                    isActive: true,
                    onTap: () {},
                  ),
                  AppComponents.bottomNavItem(
                    icon: Icons.category_rounded,
                    label: 'Kategori',
                    isActive: false,
                    onTap: () {},
                  ),
                  AppComponents.bottomNavItem(
                    icon: Icons.favorite_rounded,
                    label: 'Favorit',
                    isActive: false,
                    onTap: () {},
                  ),
                  AppComponents.bottomNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    isActive: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ============ UTILITY COMPONENTS SECTION ============
            _buildSectionTitle('Utility Components'),
            const SizedBox(height: 12),

            // Error Banner
            AppComponents.errorBanner(
              message: 'Gagal memuat berita. Periksa koneksi internet Anda.',
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Retry tapped')),
                );
              },
            ),
            const SizedBox(height: 12),

            // Success Banner
            AppComponents.successBanner(
              message: 'Berita berhasil ditambahkan ke favorit!',
            ),
            const SizedBox(height: 12),

            // Empty State
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppComponents.emptyState(
                icon: Icons.bookmark_outline_rounded,
                title: 'Tidak Ada Favorit',
                subtitle: 'Belum ada berita yang ditambahkan ke favorit',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF4F4F4F),
      ),
    );
  }
}
