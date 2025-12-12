import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/security_service.dart';
import '../../models/data_models.dart';

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
    
    // Hardcoded estateId for demo (from Seed)
    final result = await SecurityService().validateCode(code, 'est_1');
    
    setState(() {
      _isLoading = false;
      _scanResult = result;
    });
  }

  void _handleAction(String action) {
    if (_scanResult == null || _scanResult!['pass'] == null) return;
    
    final pass = _scanResult!['pass'] as GuestPass;
    if (action == 'ENTRY') {
      SecurityService().processEntry(pass.id);
    } else {
      SecurityService().processExit(pass.id);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${action == 'ENTRY' ? 'Entry' : 'Exit'} Logged Successfully"),
      backgroundColor: action == 'ENTRY' ? Colors.green : Colors.blue,
    ));
    
    setState(() {
      _codeController.clear();
      _scanResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                           onPressed: () {
                             _codeController.text = '12345'; // Demo shortcut
                             _validateCode();
                           }, 
                           icon: const Icon(LucideIcons.scanLine),
                           label: const Text("Scan QR (Demo)"),
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
                    Text(_scanResult!['message'], style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => setState(() => _scanResult = null), child: const Text("Clear"))
                  ],
                ),
              )
             else 
              _buildPassCard(context, _scanResult!['pass'] as GuestPass),
          ]
        ],
      ),
    );
  }

  Widget _buildPassCard(BuildContext context, GuestPass pass) {
    final bool isCheckedIn = pass.status == PassStatus.CHECKED_IN;
    final color = pass.status == PassStatus.ACTIVE ? Colors.green : Colors.blue;
    
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
              pass.status == PassStatus.ACTIVE ? 'READY FOR ENTRY' : 'READY FOR EXIT',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(pass.guestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(height: 8),
                Text("Visiting: ${pass.hostName}", style: TextStyle(color: Colors.grey.shade600)),
                Text("Unit ${pass.hostUnit}", style: TextStyle(color: Colors.grey.shade600)),
                
                if (pass.type == PassType.DELIVERY)
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
                  
                if (pass.exitInstruction != null && isCheckedIn)
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
                        Text(pass.exitInstruction!, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
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
}
