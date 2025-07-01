import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // <-- Import provider
import '../services/auth_service.dart';
import '../providers/theme_provider.dart'; // <-- Import ThemeProvider

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? user = FirebaseAuth.instance.currentUser;
    // Panggil ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null ? Text(user.displayName?[0] ?? 'U', style: const TextStyle(fontSize: 40)) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(user.displayName ?? 'Pengguna', style: Theme.of(context).textTheme.headlineSmall),
                  Text(user.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          const Divider(),
          // ... (ListTile untuk Bookmarks & Notifikasi)
          ListTile(
            leading: const Icon(Icons.nightlight_round),
            title: const Text('Mode Malam'),
            trailing: Switch(
              // Hubungkan value dan onChanged ke ThemeProvider
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}