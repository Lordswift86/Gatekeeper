import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../models/data_models.dart';
import '../services/security_service.dart';
import 'views/scanner_view.dart';
import 'views/deliveries_view.dart';
import 'views/intercom_view.dart';
import 'views/logbook_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isOffline = false;
  List<EmergencyAlert> _activeAlerts = [];
  Timer? _alertTimer;

  final List<Widget> _views = [
    const ScannerView(),
    const DeliveriesView(),
    const IntercomView(),
    const LogbookView(),
  ];

  @override
  void initState() {
    super.initState();
    _startAlertPolling();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  void _startAlertPolling() {
    _alertTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isOffline) return;
      // Hardcoded estateId for demo
      final alerts = SecurityService().getActiveAlerts('est_1');
      if (mounted) {
        setState(() => _activeAlerts = alerts);
      }
    });
  }

  void _resolveAlert(String id) {
    SecurityService().resolveAlert(id);
    setState(() {
      _activeAlerts.removeWhere((a) => a.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert Resolved")));
  }

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)?.settings.arguments as User?;
    if (user == null) return const Scaffold(body: Center(child: Text("Error: No User")));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("GateKeeper", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(user.name, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: _isOffline ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isOffline ? Colors.orange : Colors.green),
            ),
            child: TextButton.icon(
              onPressed: () {
                setState(() => _isOffline = !_isOffline);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isOffline ? "Offline Mode Enabled" : "Online Mode Restored"))
                );
              },
              icon: Icon(_isOffline ? LucideIcons.wifiOff : LucideIcons.wifi, 
                size: 16, 
                color: _isOffline ? Colors.orange : Colors.green
              ),
              label: Text(_isOffline ? "OFFLINE" : "ONLINE", 
                style: TextStyle(fontSize: 12, color: _isOffline ? Colors.orange : Colors.green)
              ),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_activeAlerts.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: _activeAlerts.map((alert) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.siren, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("SOS ALERT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text("Unit ${alert.unitNumber} requested help!", style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _resolveAlert(alert.id),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                          child: const Text("RESOLVE"),
                        )
                      ],
                    ),
                  )
                ).toList(),
              ),
            ),
          Expanded(child: _views[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.scanLine), label: 'Scanner'),
          NavigationDestination(icon: Icon(LucideIcons.truck), label: 'Deliveries'),
          NavigationDestination(icon: Icon(LucideIcons.phone), label: 'Intercom'),
          NavigationDestination(icon: Icon(LucideIcons.bookOpen), label: 'Logbook'),
        ],
      ),
    );
  }
}
