import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/phone_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _currentStep = 0; // 0: Enter phone, 1: Enter OTP, 2: Enter new password
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final phone = formatPhoneForAPI(_phoneController.text);
      await EstateAdminApiClient.sendOTP(phone, purpose: 'password_reset');
      
      setState(() {
        _currentStep = 1;
        _successMessage = 'OTP sent to your phone';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }
  
  Future<void> _verifyOTPAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final phone = formatPhoneForAPI(_phoneController.text);
      
      // Verify OTP first
      final verified = await EstateAdminApiClient.verifyOTP(
        phone,
        _otpController.text,
        purpose: 'password_reset',
      );
      
      if (!verified) {
        setState(() {
          _errorMessage = 'Invalid OTP code';
          _isLoading = false;
        });
        return;
      }
      
      // Reset password
      await EstateAdminApiClient.resetPassword(phone, _passwordController.text);
      
      setState(() {
        _successMessage = 'Password reset successfully!';
        _isLoading = false;
      });
      
      // Navigate back to login after a delay
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
      
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
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_reset,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _getStepTitle(),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getStepSubtitle(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Error/Success message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
                ),
              
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(_successMessage!, style: TextStyle(color: Colors.green.shade900)),
                ),
              
              // Step content
              if (_currentStep == 0) ...[
                PhoneNumberField(controller: _phoneController),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ],
              
              if (_currentStep == 1) ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    hintText: 'Enter 6-digit code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sms),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter OTP code';
                    }
                    if (value.length != 6) {
                      return 'OTP must be 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTPAndResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset Password'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _otpController.clear();
                      _errorMessage = null;
                      _successMessage = null;
                    });
                  },
                  child: const Text('Resend OTP'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Reset Password';
      case 1:
        return 'Verify & Reset';
      default:
        return 'Reset Password';
    }
  }
  
  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter your phone number to receive an OTP';
      case 1:
        return 'Enter the OTP and your new password';
      default:
        return '';
    }
  }
}
