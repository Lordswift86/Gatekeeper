import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/phone_input.dart';
import '../widgets/otp_verification_dialog.dart';
import '../models/user_role.dart';

class RegistrationScreen extends StatefulWidget {
  final UserRole role;
  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _phoneVerified = false;

  // Generic User fields
  // Note: Residents register with Email (per schema), Admins with Phone (per existing app).
  // But let's check if Residents can likely use Phone too. 
  // Schema said: identifier: Email or Phone (Login), but Register had specific fields.
  // Admin flow uses Phone. Resident flow typically uses Email in this system? 
  // Let's assume Residents use Email for now based on Schema. Or we can ask for both.
  // For Estate Admin: Name, Phone (as ID), Password.
  // For Resident: Name, Email (as ID), Password, Estate Code, Unit Number.
  // BUT: OTP is SMS based? Admin sends OTP to Phone.
  // Does Resident need OTP? Schema doesn't strictly enforce it in register endpoint, but maybe UI should?
  // Let's stick to what the endpoints expect.
  
  final _phoneController = TextEditingController(); // Used for Admin
  final _emailController = TextEditingController(); // Used for Resident
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estate Admin fields
  final _estateNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Resident fields
  final _estateCodeController = TextEditingController();
  final _unitNumberController = TextEditingController();

  bool get isResident => widget.role == UserRole.resident;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _estateNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _estateCodeController.dispose();
    _unitNumberController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone = formatPhoneForAPI(_phoneController.text);
      await ApiClient.sendOTP(phone);

      if (mounted) {
        final verified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => OTPVerificationDialog(
            phoneNumber: phone,
            onVerify: (code) async {
              final result = await ApiClient.verifyOTP(phone, code);
              if (result) {
                setState(() => _phoneVerified = true);
              }
              return result;
            },
            onResend: () async {
              await ApiClient.sendOTP(phone);
            },
          ),
        );

        if (verified == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified! Continue with registration.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // OTP check only for Estate Admin (if we stick to existing flow)
    if (!isResident && !_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone number first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (isResident) {
         result = await ApiClient.register(
           name: _nameController.text.trim(),
           email: _emailController.text.trim(),
           password: _passwordController.text,
           role: UserRole.resident.apiValue,
           estateCode: _estateCodeController.text.trim(),
           unitNumber: _unitNumberController.text.trim(),
         );
      } else {
        final phone = formatPhoneForAPI(_phoneController.text);
        result = await ApiClient.registerEstateAdmin(
          user: {
            'phone': phone,
            'name': _nameController.text.trim(),
            'password': _passwordController.text,
          },
          estate: {
            'name': _estateNameController.text.trim(),
            'address': _addressController.text.trim(),
            'description': _descriptionController.text.trim(),
          },
        );
      }

      if (mounted) {
        // Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? (isResident ? 'Account created.' : 'Awaiting approval')),
                if (!isResident && result['estateCode'] != null) ...[
                   const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Estate Code:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          result['estateCode'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                   const Text('Save this code.'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Pop until we are back to LoginScreen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Return to Login'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Step> _buildSteps() {
    final steps = <Step>[];

    // STEP 1: Personal Info
    steps.add(Step(
      title: const Text('Personal Information'),
      isActive: _currentStep >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isResident) ...[
             PhoneNumberField(
                controller: _phoneController,
                enabled: !_phoneVerified,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _phoneVerified || _isLoading ? null : _sendOTP,
                icon: Icon(_phoneVerified ? Icons.check_circle : Icons.sms),
                label: Text(_phoneVerified
                    ? 'Phone Verified ✓'
                    : 'Send Verification Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _phoneVerified ? Colors.green : Colors.blue,
                ),
              ),
          ] else ...[
             TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.contains('@') ?? false ? null : 'Invalid email',
              ),
          ],
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (v!.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
        ],
      ),
    ));

    // STEP 2: Context Specific Info (Estate Creation vs Joining)
    steps.add(Step(
      title: Text(isResident ? 'Join Estate' : 'Estate Information'),
      isActive: _currentStep >= 1,
      content: Column(
        children: [
          if (!isResident) ...[
            TextFormField(
              controller: _estateNameController,
              decoration: const InputDecoration(
                labelText: 'Estate Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_work),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Estate Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ] else ...[
             TextFormField(
              controller: _estateCodeController,
              decoration: const InputDecoration(
                labelText: 'Estate Code',
                hintText: 'Enter the code provided by estate admin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
             const SizedBox(height: 16),
             TextFormField(
              controller: _unitNumberController,
              decoration: const InputDecoration(
                labelText: 'Unit / House Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ]
        ],
      ),
    ));

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isResident ? 'Resident Registration' : 'Estate Admin Registration'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
             final isLastStep = _currentStep == _buildSteps().length - 1;
             
            if (!isLastStep) {
              // Validate current step
              // Basic primitive validation here: ensure fields for current step are filled?
              // The Form key validates ALL fields. 
              // We can rely on _formKey.currentState!.validate() but that highlights errors on hidden steps?
              // Usually Stepper form validation is tricky.
              // Let's do partial validation if needed or just simple check.
              
              if (_currentStep == 0) {
                 if (_nameController.text.isEmpty || _passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                    return;
                 }
                 if (!isResident && !_phoneVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify phone')));
                    return;
                 }
                 if (isResident && (_emailController.text.isEmpty || !_emailController.text.contains('@'))) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email')));
                    return;
                 }
              }
              
              setState(() => _currentStep++);
            } else {
              _submitRegistration();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
          steps: _buildSteps(),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep < _buildSteps().length - 1 ? 'Next' : 'Submit'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    child: Text(_currentStep > 0 ? 'Back' : 'Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
