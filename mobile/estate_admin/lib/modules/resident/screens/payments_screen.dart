import 'package:flutter/material.dart';
import 'package:gatekeeper_estate_admin/modules/resident/models/bill.dart';
import "package:gatekeeper_estate_admin/services/api_client.dart";
import 'package:gatekeeper_estate_admin/modules/resident/services/paystack_service.dart';
import 'package:gatekeeper_estate_admin/modules/resident/widgets/custom_button.dart';
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
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final bills = await ApiClient.getUserBills();
      final profile = await ApiClient.getProfile();
      
      setState(() {
        _bills = bills;
        _userEmail = profile.email;
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
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make payments')),
      );
      return;
    }
    
    setState(() => _payingBillId = bill.id);
    
    final reference = PaystackService.generateReference();
    
    await PaystackService.makePayment(
      context: context,
      email: _userEmail!,
      amount: bill.amount,
      reference: reference,
      billId: bill.id,
      onSuccess: (ref) async {
        // Verify payment on backend and update bill status
        try {
          await ApiClient.verifyPayment(bill.id, ref);
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment Successful! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          
          await _loadData();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment recorded but verification failed: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: $message'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
    
    if (mounted) {
      setState(() => _payingBillId = null);
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

    final unpaidBills = _bills.where((b) => b.status == BillStatus.UNPAID).toList();
    final paidBills = _bills.where((b) => b.status == BillStatus.PAID).toList();
    final totalUnpaid = unpaidBills.fold<double>(0, (sum, b) => sum + b.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Bills')),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    if (unpaidBills.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Outstanding', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '₦${NumberFormat('#,##0.00').format(totalUnpaid)}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${unpaidBills.length} unpaid bill${unpaidBills.length > 1 ? 's' : ''}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    
                    if (unpaidBills.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Unpaid Bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...unpaidBills.map((bill) => _buildBillCard(bill)),
                    ],
                    
                    if (paidBills.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 12),
                      ...paidBills.take(5).map((bill) => _buildPaidBillCard(bill)),
                    ],
                    
                    // Paystack badge
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.shield, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Text('Secured by Paystack', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBillCard(Bill bill) {
    final isPayingThis = _payingBillId == bill.id;
    final isOverdue = DateTime.fromMillisecondsSinceEpoch(bill.dueDate).isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getBillIcon(bill.type), color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.type.name.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(bill.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₦${NumberFormat('#,##0').format(bill.amount)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('OVERDUE', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(bill.dueDate))}',
                  style: TextStyle(color: isOverdue ? Colors.red : Colors.grey, fontSize: 12),
                ),
                CustomButton(
                  text: 'Pay with Paystack',
                  onPressed: () => _handlePay(bill),
                  isLoading: isPayingThis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidBillCard(Bill bill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
        ),
        title: Text(bill.description, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          bill.paidAt != null 
            ? 'Paid on ${DateFormat('MMM dd').format(DateTime.fromMillisecondsSinceEpoch(bill.paidAt!))}'
            : 'Paid',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Text('₦${NumberFormat('#,##0').format(bill.amount)}', style: TextStyle(color: Colors.grey.shade700)),
      ),
    );
  }

  IconData _getBillIcon(BillType type) {
    switch (type) {
      case BillType.SERVICE_CHARGE: return LucideIcons.building;
      case BillType.POWER: return LucideIcons.zap;
      case BillType.WASTE: return LucideIcons.trash2;
      case BillType.WATER: return LucideIcons.droplet;
    }
  }
}
