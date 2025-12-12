import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen> {
  List<dynamic> _pendingResidents = [];
  List<dynamic> _allResidents = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pending = await EstateAdminApiClient.getPendingResidents();
      final all = await EstateAdminApiClient.getAllResidents();
      setState(() {
        _pendingResidents = pending;
        _allResidents = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveResident(String userId) async {
    try {
      await EstateAdminApiClient.approveResident(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resident approved!')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: [
            Tab(text: 'Pending (${_pendingResidents.length})'),
            Tab(text: 'All Residents (${_allResidents.length})'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedTab == 0
                  ? _buildPendingList()
                  : _buildAllResidentsList(),
        ),
      ],
    );
  }

  Widget _buildPendingList() {
    if (_pendingResidents.isEmpty) {
      return const Center(child: Text('No pending approvals'));
    }

    return ListView.builder(
      itemCount: _pendingResidents.length,
      itemBuilder: (context, index) {
        final resident = _pendingResidents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(resident['name'][0]),
            ),
            title: Text(resident['name']),
            subtitle: Text('${resident['email']} • Unit: ${resident['unitNumber']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveResident(resident['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllResidentsList() {
    if (_allResidents.isEmpty) {
      return const Center(child: Text('No residents'));
    }

    return ListView.builder(
      itemCount: _allResidents.length,
      itemBuilder: (context, index) {
        final resident = _allResidents[index];
        return ListTile(
          leading: CircleAvatar(child: Text(resident['name'][0])),
          title: Text(resident['name']),
          subtitle: Text('${resident['email']} • Unit: ${resident['unitNumber']}'),
          trailing: Chip(
            label: Text(resident['isApproved'] ? 'Approved' : 'Pending'),
            backgroundColor: resident['isApproved'] ? Colors.green.shade100 : Colors.orange.shade100,
          ),
        );
      },
    );
  }
}
