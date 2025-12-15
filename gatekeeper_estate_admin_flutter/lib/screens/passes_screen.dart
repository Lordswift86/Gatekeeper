import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class PassesScreen extends StatefulWidget {
  const PassesScreen({super.key});

  @override
  State<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen> {
  List<dynamic> _passes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  Future<void> _loadPasses() async {
    setState(() => _isLoading = true);
    try {
      final passes = await EstateAdminApiClient.getEstatePasses();
      setState(() {
        _passes = passes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _passes.isEmpty
              ? const Center(child: Text('No passes'))
              : RefreshIndicator(
                  onRefresh: _loadPasses,
                  child: ListView.builder(
                    itemCount: _passes.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final pass = _passes[index];
                      return _PassCard(pass: pass);
                    },
                  ),
                ),
    );
  }
}

class _PassCard extends StatelessWidget {
  final Map<String, dynamic> pass;

  const _PassCard({required this.pass});

  @override
  Widget build(BuildContext context) {
    final status = pass['status'] ?? 'ACTIVE';
    final type = pass['type'] ?? 'ONE_TIME';
    final validFrom = DateTime.tryParse(pass['validFrom'] ?? '');
    final validUntil = DateTime.tryParse(pass['validUntil'] ?? '');

    Color statusColor = switch (status) {
      'ACTIVE' => Colors.green,
      'CHECKED_IN' => Colors.blue,
      'EXPIRED' => Colors.grey,
      'CANCELLED' => Colors.red,
      _ => Colors.orange,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(_getTypeIcon(type), color: statusColor, size: 20),
        ),
        title: Text(pass['guestName'] ?? 'Unknown Guest'),
        subtitle: Text(
          '${pass['hostUnit'] ?? 'N/A'} • ${validFrom != null ? DateFormat('MMM dd').format(validFrom) : 'N/A'} - ${validUntil != null ? DateFormat('MMM dd').format(validUntil) : 'N/A'}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(pass['code'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(fontSize: 10, color: statusColor.withOpacity(0.9), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    return switch (type) {
      'DELIVERY' => Icons.local_shipping,
      'RECURRING' => Icons.repeat,
      _ => Icons.person,
    };
  }
}
