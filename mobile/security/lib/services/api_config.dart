class ApiConfig {
  // Development
  static const String devBaseUrl = 'https://kitaniz.cloud/api';
  
  // Production
  static const String prodBaseUrl = 'https://kitaniz.cloud/api';
  
  static String get baseUrl => 
      const bool.fromEnvironment('dart.vm.product') 
          ? prodBaseUrl 
          : devBaseUrl;
  
  static const Duration timeoutDuration = Duration(seconds: 30);
}
