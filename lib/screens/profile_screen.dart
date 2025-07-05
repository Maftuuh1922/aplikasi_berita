import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart'; // Your custom authentication service
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Instantiate your AuthService to access its methods
    final AuthService authService = AuthService();
    // Access the ThemeProvider for theme toggling
    final themeProvider = Provider.of<ThemeProvider>(context);

    // In a real application, you would fetch user details (name, email, photoURL)
    // from your backend after successful login, possibly storing them in a
    // Provider or a dedicated user model. For now, we use placeholders.
    // Example of how you might get a user ID from the JWT token (requires JWT parsing library)
    // String? userId = await authService.token; // This would give the raw JWT string

    // Placeholder user data since Firebase User object is removed
    const String displayName = 'Pengguna Aplikasi';
    const String email = 'pengguna@example.com';
    const String photoUrl = 'https://placehold.co/100x100/A0A0A0/FFFFFF?text=UA'; // Placeholder image

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        automaticallyImplyLeading: false, // Keep this if you don't want a back button here
      ),
      body: ListView(
        children: [
          // User Profile Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  // Use a placeholder image or fetch from your backend
                  backgroundImage: NetworkImage(photoUrl),
                  backgroundColor: Colors.grey.shade300,
                  child: photoUrl.isEmpty // If photoUrl is empty, show initial
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
                  displayName, // Display placeholder name
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  email, // Display placeholder email
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
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
              // Call the signOut method from your AuthService
              await authService.signOut();
              // After logging out, navigate to the login screen or auth wrapper
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login'); // Or whatever your initial auth route is
              }
            },
          ),
        ],
      ),
    );
  }
}
