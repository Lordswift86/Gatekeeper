import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await EstateAdminApiClient.getEstateLogs();
      setState(() {
        _logs = logs;
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
          : _logs.isEmpty
              ? const Center(child: Text('No logs'))
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    itemCount: _logs.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _LogCard(log: log);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Manual Entry'),
      ),
    );
  }

  void _showAddLogDialog() {
    final nameController = TextEditingController();
    final destController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Manual Log Entry'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Guest Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destController,
                decoration: const InputDecoration(labelText: 'Destination (Unit)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || destController.text.isEmpty) return;
              try {
                await EstateAdminApiClient.addManualLog(
                  guestName: nameController.text,
                  destination: destController.text,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
                if (context.mounted) Navigator.pop(context);
                _loadLogs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log entry added')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final entryTime = DateTime.tryParse(log['entryTime'] ?? '');
    final exitTime = log['exitTime'] != null ? DateTime.tryParse(log['exitTime']) : null;
    final isActive = exitTime == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
          child: Icon(
            isActive ? Icons.login : Icons.logout,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(log['guestName'] ?? 'Unknown'),
        subtitle: Text(
          '${log['destination'] ?? 'N/A'} • Entry: ${entryTime != null ? DateFormat('MMM dd, h:mm a').format(entryTime) : 'N/A'}${exitTime != null ? ' • Exit: ${DateFormat('h:mm a').format(exitTime)}' : ' • Still inside'}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: log['type'] == 'MANUAL' ? Colors.orange.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                log['type'] ?? 'UNKNOWN',
                style: TextStyle(
                  fontSize: 10,
                  color: log['type'] == 'MANUAL' ? Colors.orange.shade900 : Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (log['notes'] != null) ...[
              const SizedBox(height: 4),
              const Icon(Icons.note, size: 16, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}
