// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'isi_profil_screen.dart'; // Import IsiProfilScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _currentUser;
  bool _isLoading = true; // State untuk loading data user

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Memuat data profil saat inisialisasi
  }

  // Fungsi untuk memuat data profil pengguna
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().getCurrentUser(); // Ambil data user dari AuthService
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); // Instansiasi AuthService
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Tampilkan loading spinner saat memuat data atau jika tidak ada user
    if (_isLoading || _currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Saya")),
        body: Center(
          child: _isLoading ? const CircularProgressIndicator() : const Text('Data profil tidak tersedia. Silakan login ulang.'),
        ),
      );
    }

    // Data user yang sebenarnya dari _currentUser
    final String displayName = _currentUser!.displayName ?? 'Pengguna Aplikasi';
    final String email = _currentUser!.email ?? 'email@tidakada.com';
    final String photoUrl = _currentUser!.photoUrl ?? ''; // URL foto dari backend

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigasi ke IsiProfilScreen untuk mengedit
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IsiProfilScreen()), // Perhatikan 'const' di sini
              );
              // Setelah kembali dari IsiProfilScreen, muat ulang data profil
              // Ini akan memperbarui tampilan ProfileScreen dengan data terbaru
              _loadUserProfile();
            },
          ),
        ],
      ),
      body: RefreshIndicator( // Tambahkan RefreshIndicator untuk pull-to-refresh
        onRefresh: _loadUserProfile,
        child: ListView(
          children: [
            // User Profile Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    // Gunakan NetworkImage jika photoUrl tidak kosong, jika tidak, gunakan placeholder
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: photoUrl.isEmpty
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                  // Tampilkan status verifikasi email jika belum diverifikasi
                  if (_currentUser!.isEmailVerified == false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Email Belum Diverifikasi',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),

            // Theme Toggle
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Mode Malam'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),

            // Logout Button
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}