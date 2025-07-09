import 'package:flutter/material.dart';
import 'dart:ui';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _breakingNews = true;
  bool _dailyDigest = false;
  bool _weeklyReport = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea( // Add SafeArea
        child: CustomScrollView(
          slivers: [
            // Glassmorphism App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
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
                                Colors.black.withValues(alpha: 0.5),
                                Colors.grey[900]!.withValues(alpha: 0.8),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.8),
                                Colors.grey[50]!.withValues(alpha: 0.9),
                              ],
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      title: Text(
                        'Pengaturan Notifikasi',
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
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Settings Content with proper bottom padding
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Extra bottom padding
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildGlassCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Push Notifications',
                          subtitle: 'Terima notifikasi push di perangkat',
                          value: _pushNotifications,
                          onChanged: (value) => setState(() => _pushNotifications = value),
                          icon: Icons.notifications_active,
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          title: 'Email Notifications',
                          subtitle: 'Terima notifikasi melalui email',
                          value: _emailNotifications,
                          onChanged: (value) => setState(() => _emailNotifications = value),
                          icon: Icons.email,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildGlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Jenis Notifikasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87, // Consistent title color
                            ),
                          ),
                        ),
                        _buildSwitchTile(
                          title: 'Berita Breaking',
                          subtitle: 'Notifikasi untuk berita penting',
                          value: _breakingNews,
                          onChanged: (value) => setState(() => _breakingNews = value),
                          icon: Icons.priority_high,
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          title: 'Ringkasan Harian',
                          subtitle: 'Ringkasan berita setiap hari',
                          value: _dailyDigest,
                          onChanged: (value) => setState(() => _dailyDigest = value),
                          icon: Icons.today,
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          title: 'Laporan Mingguan',
                          subtitle: 'Laporan berita setiap minggu',
                          value: _weeklyReport,
                          onChanged: (value) => setState(() => _weeklyReport = value),
                          icon: Icons.date_range,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
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
                      Colors.black.withValues(alpha: 0.4), // Darker for better contrast
                      Colors.grey[900]!.withValues(alpha: 0.7),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9), // More opaque
                      Colors.grey[50]!.withValues(alpha: 0.95),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15) // More visible border
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [Colors.blue[300]!, Colors.blue[500]!] // Lighter for dark mode
                : [Colors.blue[400]!, Colors.blue[600]!],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87, // Consistent title color
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[600], // Better subtitle contrast
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: isDark ? Colors.blue[400] : Colors.blue[600], // Consistent switch color
        activeTrackColor: isDark 
            ? Colors.blue[600]?.withValues(alpha: 0.5)
            : Colors.blue[200],
        inactiveThumbColor: isDark ? Colors.grey[400] : Colors.grey[300],
        inactiveTrackColor: isDark 
            ? Colors.grey[700]?.withValues(alpha: 0.5)
            : Colors.grey[200],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1) // More visible divider
          : Colors.black.withValues(alpha: 0.08),
      indent: 68,
      endIndent: 20,
    );
  }
}
