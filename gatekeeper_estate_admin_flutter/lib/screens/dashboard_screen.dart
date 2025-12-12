import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'residents_screen.dart';
import 'bills_screen.dart';
import 'announcements_screen.dart';
import 'passes_screen.dart';
import 'logs_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await EstateAdminApiClient.getEstateStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Widget> get _screens => [
        _DashboardHome(stats: _stats, isLoading: _isLoading),
        const ResidentsScreen(),
        const BillsScreen(),
        const AnnouncementsScreen(),
        const PassesScreen(),
        const LogsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estate Admin - ${widget.user['name']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await EstateAdminApiClient.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('Residents'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_outlined),
                selectedIcon: Icon(Icons.receipt),
                label: Text('Bills'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('Announcements'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge),
                label: Text('Passes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Logs'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isLoading;

  const _DashboardHome({this.stats, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _StatCard(
                title: 'Total Residents',
                value: stats?['totalResidents']?.toString() ?? '0',
                icon: Icons.people,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Pending Approvals',
                value: stats?['pendingResidents']?.toString() ?? '0',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Active Passes',
                value: stats?['activePasses']?.toString() ?? '0',
                icon: Icons.badge,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Unpaid Bills',
                value: stats?['unpaidBills']?.toString() ?? '0',
                icon: Icons.receipt,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(
                label: 'Approve Residents',
                icon: Icons.check_circle,
                onTap: () {},
              ),
              _ActionButton(
                label: 'Create Bill',
                icon: Icons.add_box,
                onTap: () {},
              ),
              _ActionButton(
                label: 'New Announcement',
                icon: Icons.campaign,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
