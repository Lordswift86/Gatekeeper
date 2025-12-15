import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<dynamic> _bills = [];
  bool _isLoading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final bills = await EstateAdminApiClient.getEstateBills();
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bills: $e')),
        );
      }
    }
  }

  List<dynamic> get _filteredBills {
    if (_filter == 'ALL') return _bills;
    return _bills.where((b) => b['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                _FilterChip(label: 'ALL', isSelected: _filter == 'ALL', onTap: () => setState(() => _filter = 'ALL')),
                _FilterChip(label: 'PAID', isSelected: _filter == 'PAID', onTap: () => setState(() => _filter = 'PAID')),
                _FilterChip(label: 'UNPAID', isSelected: _filter == 'UNPAID', onTap: () => setState(() => _filter = 'UNPAID')),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBills),
              ],
            ),
          ),
          
          // Bills List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBills.isEmpty
                    ? Center(child: Text('No ${_filter.toLowerCase()} bills'))
                    : RefreshIndicator(
                        onRefresh: _loadBills,
                        child: ListView.builder(
                          itemCount: _filteredBills.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final bill = _filteredBills[index];
                            return _BillCard(bill: bill);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBillDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create Bill'),
      ),
    );
  }

  void _showCreateBillDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateBillDialog(),
    ).then((_) => _loadBills());
  }
}

class CreateBillDialog extends StatefulWidget {
  const CreateBillDialog({super.key});

  @override
  State<CreateBillDialog> createState() => _CreateBillDialogState();
}

class _CreateBillDialogState extends State<CreateBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _selectedResidentId;
  String _selectedType = 'SERVICE_CHARGE';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  List<dynamic> _residents = [];
  bool _isLoadingResidents = true;

  final List<String> _billTypes = ['SERVICE_CHARGE', 'POWER', 'WASTE', 'WATER', 'SECURITY_LEVY', 'MAINTENANCE', 'UTILITY', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    try {
      final residents = await EstateAdminApiClient.getAllResidents();
      if (mounted) {
        setState(() {
          _residents = residents;
          _isLoadingResidents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingResidents = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedResidentId == null) return;

    setState(() => _isLoading = true);

    try {
      await EstateAdminApiClient.createBill(
        userId: _selectedResidentId!,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate.toIso8601String(),
        description: _descController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Bill'),
      content: SizedBox(
        width: 400,
        child: _isLoadingResidents 
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Resident'),
                        items: _residents.map((r) => DropdownMenuItem(
                          value: r['id'] as String,
                          child: Text('${r['name']} (Unit ${r['unitNumber']})'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedResidentId = v),
                        validator: (v) => v == null ? 'Select a resident' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Bill Type'),
                        items: _billTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date'),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _dueDate = date);
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(_isLoading ? 'Creating...' : 'Create Bill'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final isPaid = bill['status'] == 'PAID';
    final amount = bill['amount'] ?? 0;
    final dueDate = DateTime.tryParse(bill['dueDate'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid ? Colors.green : Colors.red,
          child: Icon(_getTypeIcon(bill['type']), color: Colors.white, size: 20),
        ),
        title: Text(bill['description'] ?? bill['type']),
        subtitle: Text('${bill['user']?['name'] ?? 'Unknown'} • Due: ${dueDate != null ? DateFormat('MMM dd, yyyy').format(dueDate) : 'N/A'}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₦${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPaid ? 'PAID' : 'UNPAID',
                style: TextStyle(fontSize: 10, color: isPaid ? Colors.green.shade900 : Colors.red.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'SERVICE_CHARGE': return Icons.home_work;
      case 'POWER': return Icons.flash_on;
      case 'WATER': return Icons.water_drop;
      case 'WASTE': return Icons.delete;
      default: return Icons.receipt;
    }
  }
}
