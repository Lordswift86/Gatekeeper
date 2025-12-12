class ApiConfig {
  // Development
  static const String devBaseUrl = 'http://localhost:3000/api';
  
  // Production (to be configured later)
  static const String prodBaseUrl = 'https://api.gatekeeper.com/api';
  
  static String get baseUrl => 
      const bool.fromEnvironment('dart.vm.product') 
          ? prodBaseUrl 
          : devBaseUrl;
  
  static const Duration timeoutDuration = Duration(seconds: 30);
}
