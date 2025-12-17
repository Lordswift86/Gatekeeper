import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/api_client.dart';
import 'dart:async';

enum AdPosition { footer, inline }

class AdBanner extends StatefulWidget {
  final AdPosition position;

  const AdBanner({super.key, required this.position});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  List<dynamic> _ads = [];
  int _currentAdIndex = 0;
  bool _isLoading = true;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAds() async {
    try {
      final ads = await ApiClient.getGlobalAds();
      if (mounted) {
        setState(() {
          _ads = ads.where((ad) => ad['isActive'] == true).toList();
          _isLoading = false;
        });
        
        if (_ads.isNotEmpty) {
          _startAdRotation();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Failed to load ads: $e');
    }
  }

  void _startAdRotation() {
    if (_ads.length <= 1) return;
    
    _adTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentAdIndex = (_currentAdIndex + 1) % _ads.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_ads.isEmpty) return const SizedBox.shrink(); // Hide if no ads

    final ad = _ads[_currentAdIndex];
    final title = ad['title'] ?? 'Sponsored';
    final content = ad['content'] ?? '';
    final type = ad['type'] ?? 'GENERAL';

    if (widget.position == AdPosition.footer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(LucideIcons.megaphone, color: Colors.yellow, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$title: ',
                                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: content,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Hide',
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
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Text(
            type == 'PROMOTION' ? 'SPONSORED' : 'ADVERTISEMENT',
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B), // Slate 800
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569), // Slate 600
            ),
          ),
        ],
      ),
    );
  }
}
