import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? user = FirebaseAuth.instance.currentUser;
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
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: user.photoURL == null
                        ? Text(
                      (user.displayName != null &&
                          user.displayName!.isNotEmpty)
                          ? user.displayName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? 'Pengguna',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          const Divider(),

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

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}
