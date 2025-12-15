import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';

class PaystackConfig {
  // Test keys - replace with live keys for production
  static const String publicKey = 'pk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  
  // Check if using test mode
  static bool get isTestMode => publicKey.startsWith('pk_test_');
}

class PaystackService {
  static Future<bool> makePayment({
    required BuildContext context,
    required String email,
    required double amount,
    required String reference,
    required String billId,
    String currency = 'NGN',
    Function(String reference)? onSuccess,
    Function(String message)? onError,
  }) async {
    // Convert amount to kobo (Paystack uses smallest currency unit)
    final amountInKobo = (amount * 100).toInt();
    
    try {
      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: PaystackConfig.publicKey,
        context: context,
        secretKey: '', // Not needed for popup
        currency: currency,
        customerEmail: email,
        amount: amountInKobo.toString(),
        reference: reference,
        onClosed: () {
          debugPrint('Payment cancelled');
        },
        onSuccess: () {
          debugPrint('Payment successful: $reference');
          onSuccess?.call(reference);
        },
      );
      return true;
    } catch (e) {
      debugPrint('Paystack error: $e');
      onError?.call(e.toString());
      return false;
    }
  }
  
  // Generate unique reference
  static String generateReference() {
    return 'GK_${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
  }
  
  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(DateTime.now().microsecond % chars.length))
    );
  }
}
