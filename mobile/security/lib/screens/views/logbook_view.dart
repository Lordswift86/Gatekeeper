import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LogbookView extends StatefulWidget {
  const LogbookView({super.key});

  @override
  State<LogbookView> createState() => _LogbookViewState();
}

class _LogbookViewState extends State<LogbookView> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await ApiClient.getLogs();
      setState(() => _logs = List<Map<String, dynamic>>.from(logs));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading logs: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addManualEntry() async {
    if (_nameController.text.isEmpty || _destController.text.isEmpty) return;

    try {
      await ApiClient.addManualLog(
        guestName: _nameController.text,
        destination: _destController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      _nameController.clear();
      _destController.clear();
      _notesController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Manual Entry Logged"))
        );
      }
      _refreshLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
        );
      }
    }
  }

  void _showEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Manual Log Entry", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Guest Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _destController, decoration: const InputDecoration(labelText: "Destination Unit", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: "Notes (Optional)", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _addManualEntry();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Log Entry"),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEntryDialog,
        icon: const Icon(LucideIcons.plus),
        label: const Text("Manual Entry"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
           // Header
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
               children: [
                 const Icon(LucideIcons.history, color: Colors.grey),
                 const SizedBox(width: 8),
                 Text("Recent Activity", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
                 const Spacer(),
                 if (_isLoading)
                   const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                 else
                   IconButton(icon: const Icon(LucideIcons.refreshCw, size: 16), onPressed: _refreshLogs)
               ],
             ),
           ),
           Expanded(
             child: _logs.isEmpty
               ? Center(
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(LucideIcons.bookOpen, size: 48, color: Colors.grey.shade300),
                       const SizedBox(height: 8),
                       Text("No log entries yet", style: TextStyle(color: Colors.grey.shade500)),
                     ],
                   ),
                 )
               : ListView.separated(
                   itemCount: _logs.length,
                   separatorBuilder: (_, __) => const Divider(height: 1),
                   itemBuilder: (context, index) {
                     final log = _logs[index];
                     final entryTime = log['entryTime'];
                     DateTime date;
                     if (entryTime is int) {
                       date = DateTime.fromMillisecondsSinceEpoch(entryTime);
                     } else if (entryTime is String) {
                       date = DateTime.parse(entryTime);
                     } else {
                       date = DateTime.now();
                     }
                     
                     final logType = log['type'] ?? 'MANUAL';
                     
                     return ListTile(
                       leading: CircleAvatar(
                          backgroundColor: logType == 'DIGITAL' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          child: Icon(logType == 'DIGITAL' ? LucideIcons.qrCode : LucideIcons.pencil, size: 16, color: logType == 'DIGITAL' ? Colors.green : Colors.orange),
                       ),
                       title: Text(log['guestName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                       subtitle: Text("To: ${log['destination'] ?? 'N/A'} • ${log['notes'] ?? ''}"),
                       trailing: Text(DateFormat.jm().format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                     );
                   },
                 ),
           ),
        ],
      ),
    );
  }
}
