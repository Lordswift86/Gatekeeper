import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/security_service.dart';
import '../models/data_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
       setState(() { _isLoading = false; _error = 'Please enter an email'; });
       return;
    }

    final user = await SecurityService().login(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (user != null) {
        if (user.role == UserRole.SECURITY || user.role == UserRole.SUPER_ADMIN) { // Allow Super Admin for testing
             Navigator.pushReplacementNamed(context, '/dashboard', arguments: user);
        } else {
             setState(() => _error = 'Access Denied: Security Personnel Only');
        }
      } else {
        setState(() => _error = 'User not found');
      }
    }
  }

  void _quickLogin(String email) {
    _emailController.text = email;
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade900, Colors.blueGrey.shade900]
          )
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Container(
                   width: 80,
                   height: 80,
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: Colors.white.withOpacity(0.2))
                   ),
                   child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 40),
                 ),
                 const SizedBox(height: 24),
                 const Text("GateKeeper Security", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                 const Text("Secure Entry Management", style: TextStyle(color: Colors.indigoAccent, fontSize: 16)),
                 const SizedBox(height: 48),

                 Container(
                   constraints: const BoxConstraints(maxWidth: 400),
                   padding: const EdgeInsets.all(32),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(24),
                     boxShadow: [
                       BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                     ]
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       Text("Sign In", style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 20, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 24),
                       
                       TextField(
                         controller: _emailController,
                         decoration: InputDecoration(
                           labelText: "Email Address",
                           prefixIcon: Icon(LucideIcons.user, color: Colors.blueGrey.shade400),
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                           filled: true,
                           fillColor: Colors.blueGrey.shade50
                         ),
                       ),
                       
                       if (_error.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 16),
                           child: Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                             child: Row(children: [
                               const Icon(LucideIcons.alertCircle, color: Colors.red, size: 16),
                               const SizedBox(width: 8),
                               Expanded(child: Text(_error, style: TextStyle(color: Colors.red.shade800, fontSize: 13)))
                             ]),
                           ),
                         ),

                       const SizedBox(height: 24),
                       
                       ElevatedButton(
                         onPressed: _isLoading ? null : _handleLogin,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.indigo,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           elevation: 0
                         ),
                         child: _isLoading 
                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                           : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       ),

                       const SizedBox(height: 24),
                       const Center(child: Text("Quick Demo Logins", style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                       const SizedBox(height: 12),
                       
                       _QuickLoginButton(
                         label: "Sam Security", 
                         subtitle: "Security Guard",
                         onTap: () => _quickLogin('sam@sunset.com')
                       ),
                     ],
                   ),
                 )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLoginButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLoginButton({required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12)),
              ],
            ),
            const Icon(LucideIcons.arrowRight, size: 16, color: Colors.indigo)
          ],
        ),
      ),
    );
  }
}
