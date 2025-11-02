import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBlurNavigation = false;
  User? _currentUser; // Menggunakan User dari Firebase
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _loadUserData();
  }

  // Mengambil data pengguna langsung dari Firebase Auth
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_showBlurNavigation) {
        setState(() => _showBlurNavigation = true);
      } else if (_scrollController.offset <= 100 && _showBlurNavigation) {
        setState(() => _showBlurNavigation = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      // Jika user null setelah loading, tampilkan pesan error atau arahkan ke login
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat data pengguna.',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Kembali ke Login'),
              )
            ],
          ),
        ),
      );
    }

    // Data dari Firebase User
    final String displayName = _currentUser?.displayName ?? 'Pengguna Baru';
    final String email = _currentUser?.email ?? 'Tidak ada email';
    final String? photoUrl = _currentUser?.photoURL;
    final bool isEmailVerified = _currentUser?.emailVerified ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC), // Pastel cream background
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Simple App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFFF8F4EC),
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Profil Saya',
                    style: TextStyle(
                      color: const Color(0xFF4F4F4F),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),

              // Profile Card - Elevated Design
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar with Badge
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    photoUrl != null && photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                child: photoUrl == null || photoUrl.isEmpty
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          fontSize: 36,
                                          color: const Color(0xFF6B7280),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            // Verification Badge
                            if (isEmailVerified)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5F6368),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // User Name
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4F4F4F),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F4EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Quick Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('12', 'Artikel', Icons.article_rounded),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFFE0E0E0),
                            ),
                            _buildStatItem('8', 'Favorit', Icons.bookmark_rounded),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFFE0E0E0),
                            ),
                            _buildStatItem('24', 'Dibaca', Icons.visibility_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Menu Items
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Kartu Ganti Tema
                    _buildGlassCard(
                      isDark: isDark,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B7280),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          'Mode Tema',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4F4F4F),
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          isDark ? 'Mode Gelap' : 'Mode Terang',
                          style: TextStyle(
                            color: const Color(0xFFBDBDBD),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                          },
                          activeColor: const Color(0xFF6B7280),
                          activeTrackColor: const Color(0xFF4B5563),
                          inactiveThumbColor: const Color(0xFFBDBDBD),
                          inactiveTrackColor: const Color(0xFFF8F4EC),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Kartu Pengaturan
                    _buildGlassCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildMenuItem(
                            isDark: isDark,
                            icon: Icons.edit_outlined,
                            title: 'Edit Profil',
                            subtitle: 'Ubah nama dan foto profil',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              ).then((_) =>
                                  _loadUserData()); // Refresh data setelah kembali
                            },
                          ),
                          _buildDivider(isDark),
                          _buildMenuItem(
                            isDark: isDark,
                            icon: Icons.notifications_outlined,
                            title: 'Notifikasi',
                            subtitle: 'Atur preferensi notifikasi',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(isDark),
                          _buildMenuItem(
                            isDark: isDark,
                            icon: Icons.info_outline,
                            title: 'Tentang Aplikasi',
                            subtitle: 'Versi dan informasi lainnya',
                            onTap: () {
                              _showAboutDialog(context, isDark);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Kartu Logout
                    // Kartu Logout
                    _buildGlassCard(
                      isDark: isDark,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B7280),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          'Keluar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4F4F4F),
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'Keluar dari akun Anda',
                          style: TextStyle(
                            color: const Color(0xFFBDBDBD),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                _buildLogoutDialog(context, isDark),
                          );

                          if (shouldLogout == true) {
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login', (route) => false);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 100), // Padding bawah
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bantuan',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Untuk bantuan lebih lanjut, silakan hubungi tim support kami.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tutup',
              style: TextStyle(
                  color: isDark ? Colors.blue[400] : Colors.blue[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildMenuItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4F4F4F),
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFFBDBDBD),
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: const Color(0xFFBDBDBD),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6B7280),
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFFBDBDBD),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
      indent: 68,
      endIndent: 20,
    );
  }

  Widget _buildLogoutDialog(BuildContext context, bool isDark) {
    return AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Konfirmasi Keluar',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Apakah Anda yakin ingin keluar dari akun?',
        style: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Batal',
            style:
                TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.white : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Keluar'),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Pilih Bahasa',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
              title: const Text('Indonesia'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tentang Aplikasi',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi Berita',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versi 1.0.0',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aplikasi berita terpercaya dengan fitur komentar dan bookmark.',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                  color: isDark ? Colors.blue[400] : Colors.blue[600]),
            ),
          ),
        ],
      ),
    );
  }
}
