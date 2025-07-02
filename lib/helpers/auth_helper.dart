import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_popup.dart';

class AuthHelper {
  static final AuthService _authService = AuthService();

  // Check if user is authenticated
  static bool get isAuthenticated => _authService.currentUser != null;

  // Check if user is guest
  static bool isGuest(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['isGuest'] == true;
  }

  // Require authentication for an action
  static bool requireAuth(BuildContext context, {String? message}) {
    if (!isAuthenticated) {
      LoginPopup.show(context, message: message);
      return false;
    }
    return true;
  }

  // Get current user info
  static dynamic get currentUser => _authService.currentUser;

  // Logout user
  static Future<void> logout() async {
    await _authService.signOut();
  }
}

// Widget untuk menampilkan status user
class UserStatusWidget extends StatelessWidget {
  const UserStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (AuthHelper.isAuthenticated) {
      return Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: AuthHelper.currentUser?.photoURL != null
                ? NetworkImage(AuthHelper.currentUser!.photoURL!)
                : null,
            backgroundColor: Colors.grey.shade300,
            child: AuthHelper.currentUser?.photoURL == null
                ? Icon(Icons.person, size: 16, color: Colors.grey.shade600)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AuthHelper.currentUser?.displayName ?? 'User',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (AuthHelper.isGuest(context)) {
      return Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange.shade100,
            child: Icon(
              Icons.person_outline,
              size: 16,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Mode Tamu',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

// Custom AppBar dengan status authentication
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (AuthHelper.isAuthenticated)
          PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'logout') {
                await AuthHelper.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (route) => false,
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: AuthHelper.currentUser?.photoURL != null
                    ? NetworkImage(AuthHelper.currentUser!.photoURL!)
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: AuthHelper.currentUser?.photoURL == null
                    ? Icon(Icons.person, size: 16, color: Colors.grey.shade600)
                    : null,
              ),
            ),
          )
        else if (AuthHelper.isGuest(context))
          TextButton(
            onPressed: () => LoginPopup.show(context),
            child: const Text(
              'Login',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}