import 'package:flutter/material.dart';
import 'package:gatekeeper_estate_admin/modules/resident/models/pass.dart';
import 'package:gatekeeper_estate_admin/modules/resident/widgets/custom_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class PassCard extends StatelessWidget {
  final GuestPass pass;
  final VoidCallback onCancel;

  const PassCard({
    super.key,
    required this.pass,
    required this.onCancel,
  });

  void _sharePass(BuildContext context) {
    final validDate = DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(pass.validUntil));
    final text = 'GateKeeper Access Pass\n\nVisitor: ${pass.guestName}\nCode: ${pass.code}\nValid until: $validDate\n\nPlease show this code to security.';
    Share.share(text, subject: 'Entry Pass');
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = pass.status == PassStatus.EXPIRED;
    final isCancelled = pass.status == PassStatus.CANCELLED;
    final isCheckedIn = pass.status == PassStatus.CHECKED_IN;

    Color statusColor = Colors.green;
    if (isExpired) statusColor = Colors.grey;
    if (isCancelled) statusColor = Colors.red;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pass.guestName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pass.type.toString().split('.').last.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pass.status.toString().split('.').last,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ENTRY CODE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      pass.code,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ],
                ),
                if (!isExpired && !isCancelled)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _sharePass(context),
                        icon: const Icon(Icons.share, color: Colors.indigo),
                        tooltip: 'Share',
                      ),
                      IconButton(
                        onPressed: onCancel,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Revoke',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Valid until: ${DateFormat('h:mm a, MMM d').format(DateTime.fromMillisecondsSinceEpoch(pass.validUntil))}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
