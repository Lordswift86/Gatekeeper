import 'api_service.dart';

class EstateAdminApiClient {
  // ============= Authentication =============
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(
      '/auth/login',
      {'email': email, 'password': password},
      requiresAuth: false,
    );
    
    if (response['token'] != null) {
      await ApiService.setToken(response['token']);
    }
    
    return response;
  }
  
  static Future<void> logout() async {
    await ApiService.clearToken();
  }
  
  // ============= Dashboard Stats =============
  
  static Future<Map<String, dynamic>> getEstateStats() async {
    final response = await ApiService.get('/estates/stats');
    return response;
  }
  
  // ============= Residents Management =============
  
  static Future<List<dynamic>> getPendingResidents() async {
    final response = await ApiService.get('/users/pending');
    return response as List;
  }
  
  static Future<void> approveResident(String userId) async {
    await ApiService.post('/users/$userId/approve', {});
  }
  
  static Future<void> rejectResident(String userId) async {
    await ApiService.post('/users/$userId/reject', {});
  }
  
  static Future<List<dynamic>> getAllResidents() async {
    final response = await ApiService.get('/users/residents');
    return response as List;
  }
  
  // ============= Bills Management =============
  
  static Future<List<dynamic>> getEstateBills() async {
    final response = await ApiService.get('/bills/estate');
    return response as List;
  }
  
  static Future<Map<String, dynamic>> createBill({
    required String userId,
    required String type,
    required double amount,
    required String dueDate,
    required String description,
  }) async {
    final response = await ApiService.post('/bills', {
      'userId': userId,
      'type': type,
      'amount': amount,
      'dueDate': dueDate,
      'description': description,
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
  
  static Future<void> deleteAnnouncement(String id) async {
    await ApiService.post('/security/announcements/$id/delete', {});
  }
  
  // ============= Passes =============
  
  static Future<List<dynamic>> getEstatePasses() async {
    final response = await ApiService.get('/passes/estate');
    return response as List;
  }
  
  // ============= Security Logs =============
  
  static Future<List<dynamic>> getEstateLogs() async {
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
}
