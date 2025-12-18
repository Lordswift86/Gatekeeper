import 'package:flutter/material.dart';
import 'package:gatekeeper_estate_admin/providers/theme_provider.dart';
import 'package:gatekeeper_estate_admin/services/api_client.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ApiClient.logout();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            secondary: const Icon(LucideIcons.moon),
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),
          SwitchListTile(
            secondary: const Icon(LucideIcons.bell),
            title: const Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notificationsEnabled', value);
            },
          ),
          const Divider(),
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(LucideIcons.user),
            title: const Text('Profile'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile editing coming soon')));
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.lock),
            title: const Text('Privacy & Security'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings coming soon')));
            },
          ),
          const Divider(),
          _buildSectionHeader('Support'),
          ListTile(
            leading: const Icon(LucideIcons.helpCircle),
            title: const Text('Help & Support'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(LucideIcons.info),
            title: const Text('About'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Gatekeeper Resident',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Gatekeeper',
              );
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(LucideIcons.logOut),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
