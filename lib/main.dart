import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'services/bookmark_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/auth_wrapper.dart'; // Import AuthWrapper

void main() async {
  // Memastikan semua plugin Flutter terinisialisasi sebelum menjalankan aplikasi.
  WidgetsFlutterBinding.ensureInitialized();
  // Menginisialisasi Firebase untuk platform saat ini (iOS, Android, web).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Enum untuk membedakan sumber berita, bisa digunakan nanti.
enum NewsSource { indo, luar }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider digunakan untuk menyediakan beberapa service/state ke seluruh widget tree.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => BookmarkService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Aplikasi Berita',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // Menggunakan AuthWrapper sebagai halaman utama untuk memeriksa status login.
            home: const AuthWrapper(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/bookmarks': (context) => const BookmarksScreen(),
            },
          );
        },
      ),
    );
  }
}
