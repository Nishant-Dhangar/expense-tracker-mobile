import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;
  final Map<String, dynamic> user;

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.user['name']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final updatedUser =
          await widget.authService.updateProfile(name);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );

      Navigator.pop(context, updatedUser);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user['email']?.toString() ?? '';
    final currentName =
        widget.user['name']?.toString() ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
  padding: const EdgeInsets.all(24),
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
  child: Column(
    children: [
      CircleAvatar(
        radius: 42,
        backgroundColor:
            Theme.of(context).colorScheme.primary,
        child: Text(
          _getInitials(currentName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      const SizedBox(height: 14),

      Text(
        currentName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 4),

      Text(
        email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
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

          const SizedBox(height: 36),

          Text(
  'Account Information',
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

          const SizedBox(height: 10),

         TextField(
  controller: _nameController,
  textCapitalization: TextCapitalization.words,
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
  decoration: InputDecoration(
    labelText: 'Name',
    prefixIcon: Icon(
      Icons.person_outline_rounded,
      color: Theme.of(context).colorScheme.primary,
    ),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.35),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      ),
    ),
  ),
),
          const SizedBox(height: 20),
TextField(
  enabled: false,
  controller: TextEditingController(
    text: email,
  ),
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Theme.of(context)
        .textTheme
        .bodyLarge
        ?.color
        ?.withValues(alpha: 0.65),
  ),
  decoration: InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(
      Icons.email_outlined,
      color: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.color
          ?.withValues(alpha: 0.55),
    ),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.35),
      ),
    ),
  ),
),

          const SizedBox(height: 30),

         SizedBox(
  height: 54,
  child: ElevatedButton.icon(
    onPressed: isSaving ? null : _saveProfile,
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    icon: isSaving
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          )
        : const Icon(
            Icons.check_rounded,
          ),
    label: Text(
      isSaving ? 'Saving...' : 'Save Changes',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),
        ],
      ),
    );
  }

  String _getInitials(String name) {
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
}