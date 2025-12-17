import 'package:flutter/material.dart';
import 'package:gatekeeper_estate_admin/modules/resident/main.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gatekeeper_estate_admin/modules/resident/providers/user_provider.dart';
import 'package:gatekeeper_estate_admin/modules/resident/screens/household_screen.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _privacy = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive alerts when guests arrive.'),
                  secondary: const Icon(LucideIcons.bell),
                  value: _notifications,
                  onChanged: (val) => setState(() => _notifications = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle app theme.'),
                  secondary: const Icon(LucideIcons.moon),
                  value: isDark,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Privacy Mode'),
                  subtitle: const Text('Hide details from logs after 30 days.'),
                  secondary: const Icon(LucideIcons.shield),
                  value: _privacy,
                  onChanged: (val) => setState(() => _privacy = val),
                ),

              ],
            ),
          ),

          if (Provider.of<UserProvider>(context, listen: false).user?.primaryUserId == null) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'Household'),
            Card(
              child: ListTile(
                leading: const Icon(LucideIcons.users),
                title: const Text('Manage Household'),
                subtitle: const Text('Add family members & sub-accounts.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HouseholdScreen()));
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          _SectionHeader(title: 'Security'),
          Card(
            child: ListTile(
              leading: const Icon(LucideIcons.key),
              title: const Text('Change Password'),
              subtitle: const Text('Update your login credentials.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset link sent to email.')));
              },
            ),
          ),

          const SizedBox(height: 24),
           Center(
             child: TextButton.icon(
               onPressed: () {
                 Navigator.pushReplacementNamed(context, '/login');
               },
               icon: const Icon(Icons.logout, color: Colors.red),
               label: const Text('Log Out', style: TextStyle(color: Colors.red)),
             ),
           )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).colorScheme.primary
        ),
      ),
    );
  }
}
