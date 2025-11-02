import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _breakingNews = true;
  bool _dailyDigest = false;
  bool _weeklyReport = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pushEnabled = await NotificationService.isPushNotificationsEnabled();
    final breakingEnabled = await NotificationService.isBreakingNewsEnabled();
    final emailEnabled = await NotificationService.isEmailNotificationsEnabled();
    final dailyEnabled = await NotificationService.isDailyDigestEnabled();
    final weeklyEnabled = await NotificationService.isWeeklyReportEnabled();

    if (mounted) {
      setState(() {
        _pushNotifications = pushEnabled;
        _breakingNews = breakingEnabled;
        _emailNotifications = emailEnabled;
        _dailyDigest = dailyEnabled;
        _weeklyReport = weeklyEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePushNotificationSetting(bool value) async {
    await NotificationService.setPushNotificationsEnabled(value);
    setState(() => _pushNotifications = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Push Notifications diaktifkan'
                : 'Push Notifications dinonaktifkan',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveBreakingNewsSetting(bool value) async {
    await NotificationService.setBreakingNewsEnabled(value);
    setState(() => _breakingNews = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Notifikasi Breaking News diaktifkan'
                : 'Notifikasi Breaking News dinonaktifkan',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveEmailNotificationSetting(bool value) async {
    await NotificationService.setEmailNotificationsEnabled(value);
    setState(() => _emailNotifications = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Email Notifications diaktifkan'
                : 'Email Notifications dinonaktifkan',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveDailyDigestSetting(bool value) async {
    await NotificationService.setDailyDigestEnabled(value);
    setState(() => _dailyDigest = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Ringkasan Harian diaktifkan'
                : 'Ringkasan Harian dinonaktifkan',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveWeeklyReportSetting(bool value) async {
    await NotificationService.setWeeklyReportEnabled(value);
    setState(() => _weeklyReport = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Laporan Mingguan diaktifkan'
                : 'Laporan Mingguan dinonaktifkan',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea(
        // Add SafeArea
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Pengaturan Notifikasi',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Settings Content with proper bottom padding
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  20, 20, 20, 120), // Extra bottom padding
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
                          onChanged: (value) =>
                              _savePushNotificationSetting(value),
                          icon: Icons.notifications_active,
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          title: 'Email Notifications',
                          subtitle: 'Terima notifikasi melalui email',
                          value: _emailNotifications,
                          onChanged: (value) =>
                              _saveEmailNotificationSetting(value),
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
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87, // Consistent title color
                            ),
                          ),
                        ),
                        _buildSwitchTile(
                          title: 'Berita Breaking',
                          subtitle: 'Notifikasi untuk berita penting',
                          value: _breakingNews,
                          onChanged: (value) => _saveBreakingNewsSetting(value),
                          icon: Icons.priority_high,
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          title: 'Ringkasan Harian',
                          subtitle: 'Ringkasan berita setiap hari',
                          value: _dailyDigest,
                          onChanged: (value) =>
                              _saveDailyDigestSetting(value),
                          icon: Icons.today,
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          title: 'Laporan Mingguan',
                          subtitle: 'Laporan berita setiap minggu',
                          value: _weeklyReport,
                          onChanged: (value) =>
                              _saveWeeklyReportSetting(value),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white : Colors.black,
          width: 1,
        ),
      ),
      child: child,
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(icon, color: isDark ? Colors.black : Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDark ? Colors.black : Colors.white,
          activeTrackColor: isDark ? Colors.white : Colors.black,
          inactiveThumbColor: isDark ? Colors.grey[600] : Colors.grey[400],
          inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[300],
        ),
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
