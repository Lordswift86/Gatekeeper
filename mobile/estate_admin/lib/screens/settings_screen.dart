import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/transfer_admin_dialog.dart';

class SettingsScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const SettingsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isEstateAdmin = user['role'] == 'ESTATE_ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Name'),
                    subtitle: Text(user['name'] ?? 'N/A'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(user['email'] ?? 'N/A'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.admin_panel_settings,
                      color: isEstateAdmin ? Colors.blue : null,
                    ),
                    title: const Text('Role'),
                    subtitle: Text(user['role'] ?? 'N/A'),
                  ),
                ],
              ),
            ),
          ),

          // Referral Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referrals', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: ApiClient.getReferralStats(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error loading referrals');
                      }
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      
                      final stats = snapshot.data!;
                      final referralCode = stats['referralCode'] ?? 'N/A';
                      final totalReferrals = stats['totalReferrals'] ?? 0;
                      
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                const Text('Your Referral Code', style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(
                                  referralCode,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Share referral code
                                    final message = 'Join Estate Admin with my referral code: $referralCode!\nDownload the app at: [App Link]';
                                    // On mobile, you'd use share_plus package: Share.share(message)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Code copied: $referralCode')),
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share Code'),
                                ),
                             ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('$totalReferrals', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  const Text('Total Referrals', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Admin Actions (only visible to Estate Admin)
          if (isEstateAdmin) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Admin Actions', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.orange),
              title: const Text('Transfer Admin Role'),
              subtitle: const Text('Transfer admin rights to another user'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const TransferAdminDialog(),
                );

                if (result == true && context.mounted) {
                  // Admin was transferred, logout user
                  await ApiClient.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                }
              },
            ),
          ],


          // General Settings
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('General', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (isEstateAdmin)
            ListTile(
              leading: const Icon(Icons.phone_in_talk, color: Colors.green),
              title: const Text('Security Contact'),
              subtitle: FutureBuilder<Map<String, dynamic>>(
                future: ApiClient.getEstate(user['estateId'] ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final phone = snapshot.data!['securityPhone'] ?? 'Not configured';
                    return Text(phone);
                  }
                  return const Text('Loading...');
                },
              ),
              trailing: const Icon(Icons.edit, size: 16),
              onTap: () => _updateSecurityPhone(context, user['estateId']),
            ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Estate Admin',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.admin_panel_settings, size: 48),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ApiClient.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateSecurityPhone(BuildContext context, String? estateId) async {
    if (estateId == null) return;

    // Fetch current value first
    String currentPhone = '';
    try {
      final estate = await ApiClient.getEstate(estateId);
      currentPhone = estate['securityPhone'] ?? '';
    } catch (_) {}

    final controller = TextEditingController(text: currentPhone);

    if (!context.mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the phone number that residents will call when they tap "Call Gate".'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+234...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      try {
        await ApiClient.updateEstate(estateId, {'securityPhone': result});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
          // Force rebuild to show new value would require converting to StatefulWidget, 
          // or we rely on FutureBuilder re-triggering if parent rebuilds. 
          // For now, simpler to leave as is or use a State management solution.
          // Triggering a rebuild by navigating replacement or similar hack:
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => SettingsScreen(user: user))
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
    }
  }
}
