import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../../models/data_models.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LogbookView extends StatefulWidget {
  const LogbookView({super.key});

  @override
  State<LogbookView> createState() => _LogbookViewState();
}

class _LogbookViewState extends State<LogbookView> {
  List<LogEntry> _logs = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logs = SecurityService().getEstateLogs('est_1');
    });
  }

  void _addManualEntry() {
    if (_nameController.text.isEmpty || _destController.text.isEmpty) return;

    SecurityService().addManualLogEntry('est_1', _nameController.text, _destController.text, _notesController.text);
    
    _nameController.clear();
    _destController.clear();
    _notesController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manual Entry Logged")));
    _refreshLogs();
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
                 IconButton(icon: const Icon(LucideIcons.refreshCw, size: 16), onPressed: _refreshLogs)
               ],
             ),
           ),
           Expanded(
             child: ListView.separated(
               itemCount: _logs.length,
               separatorBuilder: (_, __) => const Divider(height: 1),
               itemBuilder: (context, index) {
                 final log = _logs[index];
                 final date = DateTime.fromMillisecondsSinceEpoch(log.entryTime);
                 
                 return ListTile(
                   leading: CircleAvatar(
                      backgroundColor: log.type == 'DIGITAL' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      child: Icon(log.type == 'DIGITAL' ? LucideIcons.qrCode : LucideIcons.pencil, size: 16, color: log.type == 'DIGITAL' ? Colors.green : Colors.orange),
                   ),
                   title: Text(log.guestName, style: const TextStyle(fontWeight: FontWeight.bold)),
                   subtitle: Text("To: ${log.destination} • ${log.notes ?? ''}"),
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
