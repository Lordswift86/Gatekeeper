import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/models/bill.dart';
import 'package:gatekeeper_resident/services/mock_service.dart';
import 'package:gatekeeper_resident/widgets/custom_button.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final MockService _service = MockService();
  List<Bill> _bills = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshBills();
  }

  void _refreshBills() {
    setState(() {
      _bills = _service.getUserBills(_service.currentUser!.id);
    });
  }

  Future<void> _handlePay(Bill bill) async {
    setState(() => _isLoading = true);
    await _service.payBill(bill.id);
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
      _refreshBills();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Bills')),
      body: _bills.isEmpty
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
                final isPaid = bill.status == BillStatus.PAID;

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
                                bill.status.toString().split('.').last,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text('Due: ${DateFormat('MM/dd/yyyy').format(DateTime.fromMillisecondsSinceEpoch(bill.dueDate))}', style: const TextStyle(color: Colors.grey)),
                             if (!isPaid)
                               CustomButton(
                                 text: 'Pay Now',
                                 onPressed: () => _handlePay(bill),
                                 isLoading: _isLoading,
                               ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
