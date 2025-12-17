import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static const _storage = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();
  
  static const _phoneKey = 'saved_phone';
  static const _passwordKey = 'saved_password';
  static const _biometricEnabledKey = 'biometric_enabled';
  
  // Check if biometrics are available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } catch (e) {
      return false;
    }
  }
  
  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  // Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login to Gatekeeper',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
  
  // Save credentials securely
  static Future<void> saveCredentials({
    required String phone,
    required String password,
    bool enableBiometric = false,
  }) async {
    await _storage.write(key: _phoneKey, value: phone);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _biometricEnabledKey, value: enableBiometric.toString());
  }
  
  // Get saved credentials
  static Future<Map<String, String>?> getSavedCredentials() async {
    final phone = await _storage.read(key: _phoneKey);
    final password = await _storage.read(key: _passwordKey);
    
    if (phone != null && password != null) {
      return {'phone': phone, 'password': password};
    }
    return null;
  }
  
  // Check if biometric login is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }
  
  // Clear saved credentials
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _biometricEnabledKey);
  }
  
  // Disable biometric login
  static Future<void> disableBiometric() async {
    await _storage.write(key: _biometricEnabledKey, value: 'false');
  }
}
