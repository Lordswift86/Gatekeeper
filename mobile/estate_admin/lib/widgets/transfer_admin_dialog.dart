import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TransferAdminDialog extends StatefulWidget {
  const TransferAdminDialog({super.key});

  @override
  State<TransferAdminDialog> createState() => _TransferAdminDialogState();
}

class _TransferAdminDialogState extends State<TransferAdminDialog> {
  List<dynamic> _residents = [];
  String? _selectedUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    try {
      final residents = await ApiClient.getAllResidents();
      setState(() {
        _residents = residents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading residents: $e')),
        );
      }
    }
  }

  Future<void> _confirmTransfer() async {
    if (_selectedUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: const Text(
          'Are you sure you want to transfer admin rights? You will become a regular resident and lose admin privileges.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.transferAdmin(_selectedUserId!);
      if (mounted) {
        Navigator.pop(context, true); // Close dialog with success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin role transferred successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Admin Role'),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _residents.isEmpty
                ? const Text('No residents available')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select the new estate admin:'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Resident',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedUserId,
                        items: _residents.map((resident) {
                          return DropdownMenuItem<String>(
                            value: resident['id'],
                            child: Text('${resident['name']} (${resident['unitNumber'] ?? 'N/A'})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedUserId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This action cannot be undone. The selected user will become the new admin.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedUserId == null ? null : _confirmTransfer,
          child: const Text('Transfer'),
        ),
      ],
    );
  }
}
