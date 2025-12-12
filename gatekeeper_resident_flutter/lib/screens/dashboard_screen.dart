import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/models/pass.dart';
import 'package:gatekeeper_resident/models/user.dart';
import 'package:gatekeeper_resident/services/mock_service.dart';
import 'package:gatekeeper_resident/widgets/pass_card.dart';
import 'package:gatekeeper_resident/widgets/custom_button.dart';
import 'package:gatekeeper_resident/widgets/ad_banner.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MockService _service = MockService();
  User? _user;
  List<GuestPass> _activePasses = [];
  bool _isAccessRestricted = false;

  @override
  void initState() {
    super.initState();
    _user = _service.currentUser;
    _refreshData();
  }

  void _refreshData() {
    if (_user == null) return;
    setState(() {
      _activePasses = _service.getUserPasses(_user!.id)
          .where((p) => p.status == PassStatus.ACTIVE || p.status == PassStatus.CHECKED_IN)
          .toList();
      _isAccessRestricted = _service.checkAccessRestricted(_user!.id);
    });
  }

  void _createPass(PassType type) {
    if (_isAccessRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Restricted: Please pay overdue bills.')));
      return;
    }
    // Simple dialog for creation
    showDialog(
      context: context,
      builder: (context) => CreatePassDialog(
        type: type,
        onCreated: () {
          _refreshData();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               Navigator.pushReplacementNamed(context, '/login');
            },
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
        onRefresh: () async => _refreshData(),
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
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   TextButton.icon(
                     onPressed: () {},
                     icon: const Icon(LucideIcons.phone, color: Colors.green),
                     label: const Text('Call Security', style: TextStyle(fontWeight: FontWeight.bold)),
                   ),
                   ElevatedButton.icon(
                     onPressed: () {},
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
                onCancel: () {
                   _service.cancelPass(pass.id);
                   _refreshData();
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
  final MockService _service = MockService();

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
              labelText: isDelivery ? 'Delivery Company (e.g. Uber)' : 'Guest Name',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            _service.generatePass(
              userId: _service.currentUser!.id,
              guestName: isDelivery ? 'Delivery' : _nameController.text,
              type: widget.type,
              deliveryCompany: isDelivery ? _nameController.text : null,
            );
            widget.onCreated();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
