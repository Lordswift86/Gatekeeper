import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPVerificationDialog extends StatefulWidget {
  final String phoneNumber;
  final Function(String) onVerify;
  final VoidCallback onResend;

  const OTPVerificationDialog({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _remainingSeconds = 600; // 10 minutes
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() => _remainingSeconds = 600);
    _timer?.cancel();
    _startTimer();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-submit when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      _verifyOTP();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _verifyOTP() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await widget.onVerify(code);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOTP() async {
    try {
      await widget.onResend();
      _resetTimer();
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Phone Number'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.phoneNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onChanged(index, value),
                    onTap: () {
                      // Clear field on tap
                      _controllers[index].clear();
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds > 60 ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 20,
                    color: _remainingSeconds > 60 ? Colors.blue : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expires in $_formattedTime',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds > 60 ? Colors.blue.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Resend Button
            TextButton.icon(
              onPressed: _remainingSeconds < 540 ? _resendOTP : null, // Can resend after 1 min
              icon: const Icon(Icons.refresh),
              label: Text(_remainingSeconds >= 540 
                ? 'Wait ${600 - _remainingSeconds}s to resend' 
                : 'Resend OTP'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyOTP,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
