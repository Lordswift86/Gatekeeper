import 'package:flutter/material.dart';
import 'package:gatekeeper_estate_admin/modules/resident/models/pass.dart';
import 'package:gatekeeper_estate_admin/modules/resident/services/mock_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final MockService _service = MockService();
  List<GuestPass> _history = [];

  @override
  void initState() {
    super.initState();
    _history = _service.getUserPasses(_service.currentUser!.id)
        .where((p) => p.status == PassStatus.EXPIRED || p.status == PassStatus.CANCELLED)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pass History')),
      body: _history.isEmpty 
        ? const Center(child: Text('No history found.', style: TextStyle(color: Colors.grey)))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final pass = _history[index];
              return ListTile(
                title: Text(pass.guestName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Created: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(pass.createdAt))}'),
                trailing: Chip(
                  label: Text(pass.status.toString().split('.').last, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.grey.shade200,
                ),
              );
            },
          ),
    );
  }
}
