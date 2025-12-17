import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/phone_input.dart';
import '../widgets/phone_input.dart';
import 'dashboard_screen.dart' as admin;
import '../modules/resident/screens/dashboard_screen.dart' as resident;
import '../modules/security/screens/dashboard_screen.dart' as security;
import 'role_selection_screen.dart';
import '../services/biometric_auth_service.dart';
import '../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkSavedCredentials();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await BiometricAuthService.isBiometricAvailable();
    setState(() {
      _canCheckBiometrics = isAvailable;
    });
  }

  Future<void> _checkSavedCredentials() async {
    final credentials = await BiometricAuthService.getSavedCredentials();
    if (credentials != null && await BiometricAuthService.isBiometricEnabled()) {
      _authenticateWithBiometrics(credentials['phone']!, credentials['password']!);
    }
  }

  Future<void> _authenticateWithBiometrics(String phone, String password) async {
    final authenticated = await BiometricAuthService.authenticateWithBiometrics();
    if (authenticated) {
      _phoneController.text = phone;
      _passwordController.text = password;
      _login(isBiometric: true);
    }
  }

  Future<void> _login({bool isBiometric = false}) async {
    if (!isBiometric && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = formatPhoneForAPI(_phoneController.text);
      
      final result = await ApiClient.login(
        phone,
        _passwordController.text,
      );

      // Save credentials if login successful (and not already using biometrics)
      if (!isBiometric && _canCheckBiometrics) {
        // Ask user if they want to enable biometric login if not enabled
        if (!await BiometricAuthService.isBiometricEnabled()) {
             if (mounted) {
              final enable = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Enable Biometric Login?'),
                  content: const Text('Would you like to use FaceID/TouchID for future logins?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              
              if (enable == true) {
                await BiometricAuthService.saveCredentials(
                  phone: phone,
                  password: _passwordController.text,
                  enableBiometric: true,
                );
              }
             }
        }
      }

      if (!mounted) return;

      final role = result['user']['role'];
      Widget dashboard;
      
      switch (role) {
        case 'RESIDENT':
          dashboard = const resident.DashboardScreen();
          break;
        case 'SECURITY':
          dashboard = const security.DashboardScreen();
          break;
        case 'ESTATE_ADMIN':
        default:
          dashboard = admin.DashboardScreen(user: result['user']);
          break;
      }

      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => dashboard,
          settings: RouteSettings(arguments: result['user']),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: const RoundedRectangleBorder(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 250, // Increased height to fill space
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    PhoneNumberField(
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      onSubmitted: (_) => _login(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Reset Password'),
                              content: const Text('Please contact support to reset your password.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _login,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                    if (_canCheckBiometrics) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.fingerprint, size: 48),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () async {
                             final credentials = await BiometricAuthService.getSavedCredentials();
                             if (credentials != null) {
                               _authenticateWithBiometrics(credentials['phone']!, credentials['password']!);
                             } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('No saved credentials found. Please login securely first.')),
                               );
                             }
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Register new account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
