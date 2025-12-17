import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'residents_screen.dart';
import 'bills_screen.dart';
import 'announcements_screen.dart';
import 'passes_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

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
        _DashboardHome(
          stats: _stats, 
          isLoading: _isLoading, 
          onRefresh: _loadStats,
          onNavigate: (index) => setState(() => _selectedIndex = index),
        ),
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(user: widget.user),
                ),
              );
            },
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Residents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: 'Passes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Logs',
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(int) onNavigate;

  const _DashboardHome({this.stats, required this.isLoading, required this.onRefresh, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalResidents = stats?['totalResidents'] ?? 0;
    final pendingResidents = stats?['pendingResidents'] ?? 0;
    final activePasses = stats?['activePasses'] ?? 0;
    final unpaidBills = stats?['unpaidBills'] ?? 0;
    final paidBills = stats?['paidBills'] ?? 0;
    final totalRevenue = stats?['totalRevenue'] ?? 0.0;
    final visitorCount = stats?['visitorCount'] ?? 0;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                Text('Last updated: ${_formatTime(DateTime.now())}', 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Stats Grid - Compact 2x2 Layout
            GridView.count(
              crossAxisCount: 2, // Fixed 2 columns for consistent layout
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8, // Reduced from 12
              mainAxisSpacing: 8, // Reduced from 12
              childAspectRatio: 1.0, // Square cards for compact look
              children: [
                _StatCard(
                  title: 'Total Residents',
                  value: totalResidents.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                  trend: '+$pendingResidents pending',
                  trendColor: Colors.orange,
                ),
                _StatCard(
                  title: 'Active Passes',
                  value: activePasses.toString(),
                  icon: Icons.badge,
                  color: Colors.green,
                  trend: '$visitorCount visitors',
                  trendColor: Colors.green,
                ),
                _StatCard(
                  title: 'Bill Collection',
                  value: '₦${_formatAmount(totalRevenue)}',
                  icon: Icons.monetization_on,
                  color: Colors.purple,
                  trend: '$paidBills paid',
                  trendColor: unpaidBills > 0 ? Colors.red : Colors.green,
                ),
                _StatCard(
                  title: 'Pending Actions',
                  value: (pendingResidents + unpaidBills).toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  trend: 'Needs attention',
                  trendColor: Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Analytics Section - Stacked for Mobile
            Column(
              children: [
                _ChartCard(
                  title: 'Bill Status',
                  child: _SimplePieChart(
                    segments: [
                      _PieSegment('Paid', paidBills.toDouble(), Colors.green),
                      _PieSegment('Unpaid', unpaidBills.toDouble(), Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Pass Types (Today)',
                  child: _SimpleBarChart(
                    bars: [
                      _BarData('One-Time', stats?['oneTimePasses']?.toDouble() ?? 3.0, Colors.blue),
                      _BarData('Recurring', stats?['recurringPasses']?.toDouble() ?? 2.0, Colors.green),
                      _BarData('Delivery', stats?['deliveryPasses']?.toDouble() ?? 5.0, Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Approval',
                        value: '${totalResidents > 0 ? ((totalResidents - pendingResidents) / totalResidents * 100).toStringAsFixed(0) : 100}%',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Collection',
                        value: '${(paidBills + unpaidBills) > 0 ? (paidBills / (paidBills + unpaidBills) * 100).toStringAsFixed(0) : 100}%',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Quick Actions
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(
                  label: 'Approve Residents', 
                  icon: Icons.check_circle, 
                  color: Colors.green, 
                  badge: pendingResidents.toString(),
                  onTap: () => onNavigate(1), // Residents Tab
                ),
                _ActionButton(
                  label: 'Create Bill', 
                  icon: Icons.add_box, 
                  color: Colors.blue,
                  onTap: () => onNavigate(2), // Bills Tab
                ),
                _ActionButton(
                  label: 'New Announcement', 
                  icon: Icons.campaign, 
                  color: Colors.purple,
                  onTap: () => onNavigate(3), // Announcements Tab
                ),
                _ActionButton(
                  label: 'View Reports', 
                  icon: Icons.analytics, 
                  color: Colors.indigo,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  String _formatAmount(dynamic amount) {
    final num = (amount is double) ? amount : double.tryParse(amount.toString()) ?? 0;
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }
}

// Enhanced Stat Card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final Color? trendColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1, // Reduced from 2
      child: Container(
        padding: const EdgeInsets.all(8), // Reduced from 12
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Reduced from 12
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4), // Reduced from 6
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: color, size: 14), // Reduced from 16
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
            Text(value, 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Reduced from titleLarge
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(title, 
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11), // Smaller
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (trend != null) ...[ 
              const SizedBox(height: 2),
              Text(trend!, 
                style: TextStyle(fontSize: 9, color: trendColor ?? Colors.grey), // Reduced from 10
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Chart Card Container
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, 
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(height: 120, child: child),
          ],
        ),
      ),
    );
  }
}

// Simple Pie Chart Widget
class _SimplePieChart extends StatelessWidget {
  final List<_PieSegment> segments;

  const _SimplePieChart({required this.segments});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total == 0) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
    }

    return Row(
      children: [
        // Visual representation
        Expanded(
          child: CustomPaint(
            painter: _PieChartPainter(segments, total),
            child: const SizedBox.expand(),
          ),
        ),
        // Legend
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: segments.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('${s.label}: ${s.value.toInt()}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _PieSegment {
  final String label;
  final double value;
  final Color color;
  _PieSegment(this.label, this.value, this.color);
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  final double total;

  _PieChartPainter(this.segments, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 - 10 : size.height / 2 - 10;
    
    double startAngle = -3.14159 / 2;
    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple Bar Chart Widget
class _SimpleBarChart extends StatelessWidget {
  final List<_BarData> bars;

  const _SimpleBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(0, (max, b) => b.value > max ? b.value : max);
    if (maxValue == 0) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((bar) {
        final height = (bar.value / maxValue) * 90; // Reduced from 120
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6), // Reduced from 8
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              children: [
                Text(bar.value.toInt().toString(), 
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), // Reduced from 11
                  maxLines: 1,
                ),
                const SizedBox(height: 2), // Reduced from 4
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: bar.color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4
                Text(bar.label, 
                  style: const TextStyle(fontSize: 9), // Reduced from 10
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BarData {
  final String label;
  final double value;
  final Color color;
  _BarData(this.label, this.value, this.color);
}

// Mini Stat Card
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(label, 
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Action Button with Badge
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final String? badge;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.icon, this.color, this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ElevatedButton.icon(
          onPressed: onTap ?? () {},
          icon: Icon(icon, color: color ?? Colors.indigo),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            foregroundColor: color ?? Colors.indigo,
            backgroundColor: (color ?? Colors.indigo).withOpacity(0.1),
            elevation: 0,
          ),
        ),
        if (badge != null && badge != '0')
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}
