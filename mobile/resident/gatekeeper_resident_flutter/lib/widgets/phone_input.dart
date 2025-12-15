import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Limit to 10 digits (Nigerian number without country code)
    final digits = text.substring(0, text.length > 10 ? 10 : text.length);
    
    // Format: 801 234 5678
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        formatted += ' ';
      }
      formatted += digits[i];
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? labelText;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        PhoneInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: labelText ?? 'Phone Number',
        hintText: '801 234 5678',
        prefixIcon: const Icon(Icons.phone),
        prefixText: '+234 ',
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Phone number is required';
        }
        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.length != 10) {
          return 'Please enter a valid 10-digit phone number';
        }
        // Nigerian numbers start with 7, 8, or 9
        if (!['7', '8', '9'].contains(digitsOnly[0])) {
          return 'Nigerian numbers start with 7, 8, or 9';
        }
        return null;
      },
    );
  }
}

// Helper function to format phone for API
String formatPhoneForAPI(String phoneInput) {
  final digitsOnly = phoneInput.replaceAll(RegExp(r'\D'), '');
  return '+234$digitsOnly';
}
