import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/models/user.dart';
import 'package:gatekeeper_resident/services/api_client.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  List<User> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await ApiClient.getHousehold();
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addMember() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Household Member', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                 try {
                   await ApiClient.addSubAccount(nameCtrl.text, emailCtrl.text, passCtrl.text);
                   if (mounted) Navigator.pop(context);
                   _loadMembers();
                 } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                 }
              },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('My Household')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
      body: _members.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.users, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No household members yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(LucideIcons.user)),
                  title: Text(member.name),
                  subtitle: Text(member.email),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    onPressed: () async {
                      // Confirm dialog needed
                      await ApiClient.removeSubAccount(member.id);
                      _loadMembers();
                    },
                  ),
                ),
              );
            },
          ),
    );
  }
}
