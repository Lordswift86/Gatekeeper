import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'login_screen.dart';
import 'residents_screen.dart';
import 'bills_screen.dart';
import 'announcements_screen.dart';
import 'passes_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';
import '../modules/resident/widgets/ad_banner.dart'; // Import AdBanner

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
      final stats = await ApiClient.getEstateStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
              await ApiClient.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
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

  void _createPass(BuildContext context, PassType type) {
    showDialog(
      context: context,
      builder: (context) => CreatePassDialog(
        type: type,
        onCreated: () {
          onRefresh();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pass created successfully')),
          );
        },
      ),
    );
  }

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
            const SizedBox(height: 16),
            
            // Stats Row - Scrollable Horizontal
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard(
                    title: 'Total Residents',
                    value: totalResidents.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                    trend: '+$pendingResidents pending',
                    trendColor: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    title: 'Active Passes',
                    value: activePasses.toString(),
                    icon: Icons.badge,
                    color: Colors.green,
                    trend: '$visitorCount visitors',
                    trendColor: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    title: 'Bill Collection',
                    value: '₦${_formatAmount(totalRevenue)}',
                    icon: Icons.monetization_on,
                    color: Colors.purple,
                    trend: '$paidBills paid',
                    trendColor: unpaidBills > 0 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
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
            ),
            
            const SizedBox(height: 24),
            
            // Ad Banner
            const AdBanner(position: AdPosition.inline),

            const SizedBox(height: 24),
            
            // Quick Actions
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(
                  label: 'Generate Code', 
                  icon: Icons.qr_code, 
                  color: Colors.teal,
                  onTap: () => _createPass(context, PassType.ONE_TIME),
                ),
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
              ],
            ),

            const SizedBox(height: 32),
            
            // Analytics Section
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

// Enhanced Stat Card (Compact for Row)
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
    // Fixed width for horizontal scrolling consistency
    return SizedBox(
      width: 140, 
      height: 100, // Fixed height to fit row
      child: Card(
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const Spacer(),
                  Text(value, 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const Spacer(),
              Text(title, 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (trend != null) ...[ 
                const SizedBox(height: 2),
                Text(trend!, 
                  style: TextStyle(fontSize: 9, color: trendColor ?? Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Reuse Chart Widgets
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

class _SimplePieChart extends StatelessWidget {
  final List<_PieSegment> segments;
  const _SimplePieChart({required this.segments});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total == 0) return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));

    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _PieChartPainter(segments, total),
            child: const SizedBox.expand(),
          ),
        ),
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
      final paint = Paint()..color = segment.color..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SimpleBarChart extends StatelessWidget {
  final List<_BarData> bars;
  const _SimpleBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(0, (max, b) => b.value > max ? b.value : max);
    if (maxValue == 0) return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((bar) {
        final height = (bar.value / maxValue) * 90;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(bar.value.toInt().toString(), 
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: bar.color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(bar.label, 
                  style: const TextStyle(fontSize: 9),
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

// Pass Generation Dialog
enum PassType { ONE_TIME, RECURRING, DELIVERY }

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
      title: Text(isDelivery ? 'Expected Delivery' : 'New Guest Code'),
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
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Exit Instructions (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            enabled: !_isLoading,
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
            : const Text('Generate Code'),
        ),
      ],
    );
  }
}
