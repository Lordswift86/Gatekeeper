import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'dart:async';

class ResidentIdScreen extends StatefulWidget {
  const ResidentIdScreen({super.key});

  @override
  State<ResidentIdScreen> createState() => _ResidentIdScreenState();
}

class _ResidentIdScreenState extends State<ResidentIdScreen> {
  User? _user;
  String? _idToken;
  DateTime? _tokenExpiry;
  bool _isLoading = true;
  Timer? _refreshTimer;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadIdentity() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final profile = await ApiClient.getProfile();
      final idData = await ApiClient.getIdentityToken();
      
      if (!mounted) return;

      setState(() {
        _user = profile;
        _idToken = idData['token'];
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(idData['validUntil']);
        _isLoading = false;
      });

      // Set up auto-refresh before expiry (e.g. 10s before)
      final timeToRefresh = _tokenExpiry!.difference(DateTime.now()) - const Duration(seconds: 10);
      if (timeToRefresh.isNegative) {
        _loadIdentity(); // Already expired/close, refresh now
      } else {
        _refreshTimer = Timer(timeToRefresh, _loadIdentity);
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load ID. Please check connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resident ID')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadIdentity,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Resident ID'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadIdentity,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // ID Card Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 20,
                   offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header (Estate Name)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B), // Dark slate
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.building2, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                           "GATEKEEPER ESTATE", // Use user.estateName if available
                           style: const TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.bold,
                             fontSize: 18,
                             letterSpacing: 1.2,
                           ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Profile Photo
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.indigo, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _user?.photoUrl != null 
                          ? NetworkImage(_user!.photoUrl!) 
                          : null,
                      child: _user?.photoUrl == null
                          ? const Icon(LucideIcons.user, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Info
                  Text(
                    _user?.name ?? 'Resident Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _user?.unitNumber != null 
                          ? 'UNIT ${_user!.unitNumber}' 
                          : 'NO UNIT ASSIGNED',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code
                  if (_idToken != null)
                    QrImageView(
                      data: _idToken!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),

                  const SizedBox(height: 16),

                  // Status Badge
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ACTIVE RESIDENT',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Reassurance text
            const Text(
              "Show this QR code to security at the gate for quick identification.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
