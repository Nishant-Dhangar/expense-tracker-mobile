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
  try {
    await widget.authService.logout();
  } catch (_) {
    // Even if the server logout request fails,
    // clear the local session and return to Login.
  }

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
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Theme.of(context)
          .dividerColor
          .withValues(alpha: 0.15),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor:
            Theme.of(context).colorScheme.primary,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?['email'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

                const SizedBox(height: 28),

                Text(
  'Account',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.65),
  ),
),

                const SizedBox(height: 8),

               Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: Theme.of(context)
          .dividerColor
          .withValues(alpha: 0.15),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 6,
    ),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    title: const Text(
      'Profile',
      style: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      'Edit your account information',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.60),
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
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

                Text(
  'Preferences',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.65),
  ),
),

                const SizedBox(height: 8),

                Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: Theme.of(context)
          .dividerColor
          .withValues(alpha: 0.15),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Manage notifications',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.60),
          ),
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

      Divider(
        height: 1,
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.12),
      ),

      ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.dark_mode_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: const Text(
          'Dark Mode',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Change app appearance',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.60),
          ),
        ),
        trailing: Switch(
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

                Text(
  'Account Actions',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.65),
  ),
),

                const SizedBox(height: 8),

                Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: Colors.red.withValues(alpha: 0.15),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 6,
    ),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.logout_rounded,
        color: Colors.red,
      ),
    ),
    title: const Text(
      'Logout',
      style: TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      'Sign out of your account',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.60),
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
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'U';
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