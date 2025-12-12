import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/models/bill.dart';
import 'package:gatekeeper_resident/services/api_client.dart';
import 'package:gatekeeper_resident/widgets/custom_button.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Bill> _bills = [];
  bool _isLoading = true;
  String? _payingBillId;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    
    try {
      final bills = await ApiClient.getUserBills();
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bills: $e')),
      );
    }
  }

  Future<void> _handlePay(Bill bill) async {
    setState(() => _payingBillId = bill.id);
    
    try {
      await ApiClient.payBill(bill.id);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadBills();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _payingBillId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payments & Bills')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Bills')),
      body: RefreshIndicator(
        onRefresh: _loadBills,
        child: _bills.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.checkCircle, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text('All Caught Up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('No outstanding bills.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bills.length,
                itemBuilder: (context, index) {
                  final bill = _bills[index];
                  final isPaid = bill.status == BillStatus.paid;
                  final isPayingThis = _payingBillId == bill.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(LucideIcons.wallet, color: isPaid ? Colors.green : Colors.orange),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  bill.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isPaid ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('\$${bill.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(bill.description, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Type: ${bill.type.name.replaceAll('_', ' ')}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Due: ${DateFormat('MMM dd, yyyy').format(bill.dueDate)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (!isPaid)
                                CustomButton(
                                  text: 'Pay Now',
                                  onPressed: () => _handlePay(bill),
                                  isLoading: isPayingThis,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
