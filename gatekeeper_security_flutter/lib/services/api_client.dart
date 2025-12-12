import 'api_service.dart';

class ApiClient {
  // ============= Authentication =============
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(
      '/auth/login',
      {'email': email, 'password': password},
      requiresAuth: false,
    );
    
    // Store token
    if (response['token'] != null) {
      await ApiService.setToken(response['token']);
    }
    
    return {
      'user': response['user'],
      'token': response['token'],
    };
  }
  
  static Future<void> logout() async {
    await ApiService.clearToken();
  }
  
  // ============= Pass Validation =============
  
  static Future<Map<String, dynamic>> validatePass(String code) async {
    final response = await ApiService.post('/passes/validate', {
      'code': code,
    });
    return response;
  }
  
  static Future<void> processEntry(String passId) async {
    await ApiService.post('/passes/$passId/entry', {});
  }
  
  static Future<void> processExit(String passId) async {
    await ApiService.post('/passes/$passId/exit', {});
  }
  
  // ============= Security Logs =============
  
  static Future<List<dynamic>> getLogs() async {
    final response = await ApiService.get('/security/logs');
    return response as List;
  }
  
  static Future<Map<String, dynamic>> addManualLog({
    required String guestName,
    required String destination,
    String? notes,
  }) async {
    final response = await ApiService.post('/security/logs', {
      'guestName': guestName,
      'destination': destination,
      'notes': notes,
    });
    return response;
  }
  
  // ============= Announcements =============
  
  static Future<List<dynamic>> getAnnouncements() async {
    final response = await ApiService.get('/security/announcements');
    return response as List;
  }
  
  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
  }) async {
    final response = await ApiService.post('/security/announcements', {
      'title': title,
      'content': content,
    });
    return response;
  }
}
