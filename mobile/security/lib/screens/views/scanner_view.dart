import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/api_client.dart';
import 'qr_scanner_screen.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _scanResult;

  Future<void> _validateCode() async {
    final code = _codeController.text;
    if (code.length != 5) return;

    setState(() { _isLoading = true; _scanResult = null; });
    
    try {
      final result = await ApiClient.validatePass(code);
      setState(() {
        _isLoading = false;
        _scanResult = {
          'success': true,
          'pass': result,
        };
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _scanResult = {
          'success': false,
          'message': e.toString().replaceAll('Exception: ', ''),
        };
      });
    }
  }

  Future<void> _handleAction(String action) async {
    if (_scanResult == null || _scanResult!['pass'] == null) return;
    
    final pass = _scanResult!['pass'] as Map<String, dynamic>;
    final passId = pass['id'] as String;
    
    try {
      if (action == 'ENTRY') {
        await ApiClient.processEntry(passId);
      } else {
        await ApiClient.processExit(passId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${action == 'ENTRY' ? 'Entry' : 'Exit'} Logged Successfully"),
          backgroundColor: action == 'ENTRY' ? Colors.green : Colors.blue,
        ));
      }
      
      setState(() {
        _codeController.clear();
        _scanResult = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Access Control", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Code Input
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   TextField(
                     controller: _codeController,
                     keyboardType: TextInputType.number,
                     textAlign: TextAlign.center,
                     maxLength: 5,
                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                     style: const TextStyle(fontSize: 32, letterSpacing: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                     decoration: const InputDecoration(
                       hintText: 'CODE',
                       counterText: '',
                       border: OutlineInputBorder(),
                     ),
                     onChanged: (val) {
                       if (val.length == 5) _validateCode();
                     },
                   ),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(
                         child: OutlinedButton.icon(
                           onPressed: _openScanner, 
                           icon: const Icon(LucideIcons.scanLine),
                           label: const Text("Scan QR"),
                           style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: ElevatedButton(
                           onPressed: (_codeController.text.length == 5 && !_isLoading) ? _validateCode : null,
                           style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white
                           ),
                           child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Validate"),
                         ),
                       ),
                     ],
                   )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_scanResult != null) ...[
             if (_scanResult!['success'] == false)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3))
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text("Access Denied", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_scanResult!['message'] ?? 'Invalid pass', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => setState(() => _scanResult = null), child: const Text("Clear"))
                  ],
                ),
              )

             else if (_scanResult!['pass'] != null)
              _buildPassCard(context, _scanResult!['pass'] as Map<String, dynamic>)
             else if (_scanResult!['user'] != null)
              _buildIdentityCard(context, _scanResult!['user'] as Map<String, dynamic>),
          ]
        ],
      ),
    );
  }

  Widget _buildPassCard(BuildContext context, Map<String, dynamic> pass) {
    final status = pass['status'] as String?;
    final bool isCheckedIn = status == 'CHECKED_IN';
    final color = status == 'ACTIVE' ? Colors.green : Colors.blue;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16))
            ),
            child: Text(
              status == 'ACTIVE' ? 'READY FOR ENTRY' : 'READY FOR EXIT',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(pass['guestName'] ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(height: 8),
                Text("Unit ${pass['hostUnit'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600)),
                
                if (pass['type'] == 'DELIVERY')
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.truck, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("DELIVERY", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  
                if (pass['exitInstruction'] != null && isCheckedIn)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("EXIT INSTRUCTION", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(pass['exitInstruction'], style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction(isCheckedIn ? 'EXIT' : 'ENTRY'),
                    icon: Icon(isCheckedIn ? LucideIcons.logOut : LucideIcons.logIn),
                    label: Text(isCheckedIn ? "Confirm Exit" : "Grant Entry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget _buildIdentityCard(BuildContext context, Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))
            ),
            child: const Text(
              'VERIFIED RESIDENT',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
                  child: user['photoUrl'] == null ? const Icon(LucideIcons.user, size: 50, color: Colors.grey) : null,
                ),
                const SizedBox(height: 16),
                Text(user['name'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(height: 8),
                Text("Unit ${user['unitNumber'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text(user['estateName'] ?? 'Estate', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _scanResult = null),
                    icon: const Icon(LucideIcons.check),
                    label: const Text("Done"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    
    if (result != null && mounted) {
      if (result['type'] == 'IDENTITY') {
        setState(() {
          _scanResult = result['data']; // Expected { verified: true, user: ... }
        });
      } else if (result['type'] == 'PASS_CODE') {
        _codeController.text = result['code'];
        _validateCode();
      }
    }
  }
}
