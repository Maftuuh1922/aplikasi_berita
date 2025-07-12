import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
              Text('Gagal memuat data pengguna.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
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
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar dengan efek blur
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.black.withOpacity(0.5),
                                  Colors.grey[900]!.withOpacity(0.8),
                                ]
                              : [
                                  Colors.white.withOpacity(0.8),
                                  Colors.grey[50]!.withOpacity(0.9),
                                ],
                        ),
                      ),
                      child: FlexibleSpaceBar(
                        title: Text(
                          'Profil Saya',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        centerTitle: true,
                      ),
                    ),
                  ),
                ),
              ),

              // Profile Header - Menampilkan data pengguna asli
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.transparent,
                                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl == null || photoUrl.isEmpty
                                    ? Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Nama Pengguna
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Email Pengguna
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            // Lencana verifikasi email
                            if (isEmailVerified) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Terverifikasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Menu Items
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Kartu Ganti Tema
                    _buildGlassCard(
                      isDark: isDark,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [Colors.orange[400]!, Colors.orange[600]!]
                                  : [Colors.purple[400]!, Colors.purple[600]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isDark ? Icons.nightlight_round : Icons.wb_sunny,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Mode Tema',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          isDark ? 'Mode Gelap' : 'Mode Terang',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                          },
                          activeColor: Colors.white,
                          activeTrackColor: Colors.blue.shade600,
                          inactiveThumbColor: Colors.grey.shade700,
                          inactiveTrackColor: Colors.grey.shade300,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

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
                            gradientColors: [Colors.blue[400]!, Colors.blue[600]!],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              ).then((_) => _loadUserData()); // Refresh data setelah kembali
                            },
                          ),
                          _buildDivider(isDark),
                          _buildMenuItem(
                            isDark: isDark,
                            icon: Icons.notifications_outlined,
                            title: 'Notifikasi',
                            subtitle: 'Atur preferensi notifikasi',
                            gradientColors: [Colors.green[400]!, Colors.green[600]!],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationSettingsScreen(),
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
                            gradientColors: [Colors.indigo[400]!, Colors.indigo[600]!],
                            onTap: () {
                              _showAboutDialog(context, isDark);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kartu Logout
                    _buildGlassCard(
                      isDark: isDark,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red[400]!, Colors.red[600]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Keluar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[500],
                          ),
                        ),
                        subtitle: Text(
                          'Keluar dari akun Anda',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        onTap: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildLogoutDialog(context, isDark),
                          );

                          if (shouldLogout == true) {
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
              style: TextStyle(color: isDark ? Colors.blue[400] : Colors.blue[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), // Fix: Remove horizontal margin
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.black.withOpacity(0.2),
                        Colors.grey[900]!.withOpacity(0.5),
                      ]
                    : [
                        Colors.white.withOpacity(0.7),
                        Colors.grey[50]!.withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: onTap,
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
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[500],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              style: TextStyle(color: isDark ? Colors.blue[400] : Colors.blue[600]),
            ),
          ),
        ],
      ),
    );
  }
}
