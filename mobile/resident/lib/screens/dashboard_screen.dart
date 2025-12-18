import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/models/pass.dart';
import 'package:gatekeeper_resident/models/user.dart';
import 'package:gatekeeper_resident/services/api_client.dart';
import 'package:gatekeeper_resident/widgets/pass_card.dart';
import 'package:gatekeeper_resident/widgets/custom_button.dart';
import 'package:gatekeeper_resident/widgets/ad_banner.dart';
import 'package:gatekeeper_resident/screens/resident_id_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  List<GuestPass> _activePasses = [];
  bool _isAccessRestricted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await ApiClient.getProfile();
      final passes = await ApiClient.getUserPasses();
      
      setState(() {
        _user = user;
        _activePasses = passes
            .where((p) => p.status == PassStatus.ACTIVE || p.status == PassStatus.CHECKED_IN)
            .toList();
        // TODO: Check access restriction based on overdue bills
        _isAccessRestricted = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _createPass(PassType type) async {
    if (_isAccessRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access Restricted: Please pay overdue bills.')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => CreatePassDialog(
        type: type,
        onCreated: () {
          _loadData();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    await ApiClient.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load user data')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.badgeCheck),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentIdScreen()),
              );
            },
            tooltip: 'My Resident ID',
          ),
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.pushNamed(context, '/game');
          if (index == 2) Navigator.pushNamed(context, '/payments');
          if (index == 3) Navigator.pushNamed(context, '/history');
          if (index == 4) Navigator.pushNamed(context, '/settings');
        },
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.home), label: 'Home'),
          NavigationDestination(icon: Icon(LucideIcons.gamepad2), label: 'Relax'),
          NavigationDestination(icon: Icon(LucideIcons.creditCard), label: 'Pay'),
          NavigationDestination(icon: Icon(LucideIcons.history), label: 'History'),
          NavigationDestination(icon: Icon(LucideIcons.settings), label: 'Settings'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Section
            Text(
              'Welcome back, ${_user!.name.split(' ')[0]}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Unit ${_user!.unitNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            
            const SizedBox(height: 24),
            
            // Safety Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   TextButton.icon(
                     onPressed: () async {
                       if (_user?.estate?.securityPhone != null) {
                         final Uri launchUri = Uri(
                           scheme: 'tel',
                           path: _user!.estate!.securityPhone!,
                         );
                         if (await canLaunchUrl(launchUri)) {
                           await launchUrl(launchUri);
                         } else {
                           if (!mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Could not launch dialer')),
                           );
                         }
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('No security number configured for this estate.')),
                         );
                       }
                     },
                     icon: const Icon(LucideIcons.phone, color: Colors.green),
                     label: const Text('Call Security', style: TextStyle(fontWeight: FontWeight.bold)),
                   ),
                   ElevatedButton.icon(
                     onPressed: () async {
                       final confirm = await showDialog<bool>(
                         context: context,
                         builder: (context) => AlertDialog(
                           title: const Text('EMERGENCY SOS'),
                           content: const Text('This will trigger an immediate emergency alert to security. Are you sure?'),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                             ElevatedButton(
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                               onPressed: () => Navigator.pop(context, true), 
                               child: const Text('TRIGGER SOS')
                             ),
                           ],
                         ),
                       );

                       if (confirm == true) {
                         try {
                           await ApiClient.triggerSOS();
                           if (!mounted) return;
                           showDialog(
                             context: context,
                             builder: (context) => const AlertDialog(
                               title: Text('SOS SENT'),
                               content: Text('Security has been alerted and will arrive shortly.'),
                               icon: Icon(LucideIcons.siren, size: 48, color: Colors.red),
                             ),
                           );
                         } catch (e) {
                           if (!mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Failed to send SOS: $e')),
                           );
                         }
                       }
                     },
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                     icon: const Icon(LucideIcons.siren, size: 18),
                     label: const Text('SOS'),
                   )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ad Banner (Inline)
            const AdBanner(position: AdPosition.inline),

            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: LucideIcons.plus,
                    label: 'New Guest',
                    color: Colors.indigo,
                    onTap: () => _createPass(PassType.ONE_TIME),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: LucideIcons.truck,
                    label: 'Delivery',
                    color: Colors.orange,
                    onTap: () => _createPass(PassType.DELIVERY),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Active Passes
            const Text('Active Passes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_activePasses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text('No active passes', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._activePasses.map((pass) => PassCard(
                pass: pass,
                onCancel: () async {
                  try {
                    await ApiClient.cancelPass(pass.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pass cancelled')),
                    );
                    _loadData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to cancel pass: $e')),
                    );
                  }
                },
              )),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class CreatePassDialog extends StatefulWidget {
  final PassType type;
  final VoidCallback onCreated;

  const CreatePassDialog({super.key, required this.type, required this.onCreated});

  @override
  State<CreatePassDialog> createState() => _CreatePassDialogState();
}

class _CreatePassDialogState extends State<CreatePassDialog> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final isDelivery = widget.type == PassType.DELIVERY;
      
      await ApiClient.generatePass(
        guestName: isDelivery ? 'Delivery' : _nameController.text,
        type: widget.type.name,
        exitInstruction: _notesController.text.isEmpty ? null : _notesController.text,
        deliveryCompany: isDelivery ? _nameController.text : null,
      );

      if (!mounted) return;
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create pass: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = widget.type == PassType.DELIVERY;
    
    return AlertDialog(
      title: Text(isDelivery ? 'Expected Delivery' : 'New Guest'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isDelivery ? 'Delivery Company (e.g. UberEats)' : 'Guest Name',
              border: const OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.type == PassType.ONE_TIME 
                        ? 'Code expires in 12 hours'
                        : (widget.type == PassType.RECURRING 
                            ? 'Code expires in 30 days'
                            : 'Code expires in 30 minutes'),
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCreate,
          child: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Create'),
        ),
      ],
    );
  }
}
