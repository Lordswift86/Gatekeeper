import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum AdPosition { footer, inline }

class AdBanner extends StatelessWidget {
  final AdPosition position;

  const AdBanner({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    if (position == AdPosition.footer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(LucideIcons.megaphone, color: Colors.yellow, size: 16),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Sponsored: ',
                            style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'Get 50% off Smart Locks!',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Remove Ads',
                style: TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      );
    }

    // Inline Style
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Slate 100
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!, // Slate 300
          style: BorderStyle.solid, // Flutter doesn't support dashed border easily without package, solid for now or CustomPainter
        ),
      ),
      child: Column(
        children: [
          Text(
            'ADVERTISEMENT',
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Best Fiber Internet in Your Estate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B), // Slate 800
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Connect now for ultra-fast speeds.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569), // Slate 600
            ),
          ),
        ],
      ),
    );
  }
}
