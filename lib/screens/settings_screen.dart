import 'package:flutter/material.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../utils/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
class SettingsScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeManager themeManager;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.themeManager,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  bool notificationsEnabled = false;

 @override
void initState() {
  super.initState();

  _loadUser();
  _loadNotificationPreference();
}
Future<void> _loadNotificationPreference() async {
  final prefs = await SharedPreferences.getInstance();

  if (!mounted) return;

  setState(() {
    notificationsEnabled =
        prefs.getBool('notificationsEnabled') ?? false;
  });
}
Future<void> _setNotificationsEnabled(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool(
    'notificationsEnabled',
    enabled,
  );

  if (!mounted) return;

  setState(() {
    notificationsEnabled = enabled;
  });
}

  Future<void> _loadUser() async {
    try {
      final currentUser =
          await widget.authService.getCurrentUser();

      if (!mounted) return;

      setState(() {
        user = currentUser;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

 Future<void> _logout() async {
  await widget.authService.logout();

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => LoginScreen(
        themeManager: widget.themeManager,
      ),
    ),
    (route) => false,
  );
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?['name'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?['email'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                Card(
  elevation: 0,
  child: ListTile(
    leading: const Icon(
      Icons.person_outline,
    ),
    title: const Text('Profile'),
    subtitle: const Text(
      'Edit your account information',
    ),
    trailing: const Icon(
      Icons.chevron_right,
    ),
    onTap: () async {
      if (user == null) return;

      final updatedUser = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            authService: widget.authService,
            user: user!,
          ),
        ),
      );

      if (updatedUser != null && mounted) {
        setState(() {
          user = updatedUser;
        });
      }
    },
  ),
),

                const SizedBox(height: 24),

                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
  leading: const Icon(
    Icons.notifications_none,
  ),
  title: const Text('Notifications'),
  subtitle: const Text(
    'Manage notifications',
  ),
  trailing: Switch(
    value: notificationsEnabled,
   onChanged: (value) async {
  await _setNotificationsEnabled(value);

  if (value) {
    await NotificationService.showBudgetAlert(
      title: 'Notifications Enabled',
      body: 'Expense Tracker notifications are now active.',
    );
  }
},
  ),
),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.dark_mode_outlined,
                        ),
                        title: const Text('Dark Mode'),
                        subtitle: const Text(
                          'Change app appearance',
                        ),
                        trailing:Switch(
  value: widget.themeManager.isDarkMode,
  onChanged: (value) async {
    await widget.themeManager.setDarkMode(value);

    if (mounted) {
      setState(() {});
    }
  },
),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Account Actions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _showLogoutDialog,
                  ),
                ),
              ],
            ),
    );
  }

  String _initials() {
    final name = user?['name']?.toString() ?? 'U';

    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'
          .toUpperCase();
    }

    return name.substring(0, 1).toUpperCase();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}