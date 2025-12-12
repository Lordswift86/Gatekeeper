import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/security_service.dart';
import '../../models/data_models.dart';

class DeliveriesView extends StatefulWidget {
  const DeliveriesView({super.key});

  @override
  State<DeliveriesView> createState() => _DeliveriesViewState();
}

class _DeliveriesViewState extends State<DeliveriesView> {
  List<GuestPass> _deliveries = [];
  bool _isLoading = true;
  String? _verifyingId;
  final TextEditingController _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  void _loadDeliveries() {
    setState(() => _isLoading = true);
    // Hardcoded estateId for demo
    final list = SecurityService().getExpectedDeliveries('est_1');
    setState(() {
      _deliveries = list;
      _isLoading = false;
    });
  }

  void _verifyDelivery(String passId) {
    if (_plateController.text.isEmpty) return;
    
    SecurityService().verifyDelivery(passId, _plateController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delivery Verified & Checked In"), backgroundColor: Colors.green));
    
    setState(() { _verifyingId = null; _plateController.clear(); });
    _loadDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.truck, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No Expected Deliveries", style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _deliveries.length,
      itemBuilder: (context, index) {
        final pass = _deliveries[index];
        final isVerifying = _verifyingId == pass.id;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(pass.guestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("Unit ${pass.hostUnit}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                Text("Host: ${pass.hostName}", style: TextStyle(color: Colors.grey.shade600)),
                
                const SizedBox(height: 16),
                
                if (isVerifying)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _plateController,
                          decoration: const InputDecoration(
                            labelText: "Plate Number",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _verifyDelivery(pass.id),
                        icon: const Icon(LucideIcons.check, color: Colors.green),
                        style: IconButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.1)),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _verifyingId = null),
                        icon: const Icon(LucideIcons.x, color: Colors.red),
                        style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                      )
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => setState(() { _verifyingId = pass.id; _plateController.clear(); }),
                      child: const Text("Verify & Check In"),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}
