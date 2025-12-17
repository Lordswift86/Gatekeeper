import 'api_service.dart';

class EstateAdminApiClient {
  // ============= Authentication =============
  
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await ApiService.post(
      '/auth/login',
      {'phone': phone, 'password': password},
      requiresAuth: false,
    );
    
    // Backend returns 'accessToken', not 'token'
    if (response['accessToken'] != null) {
      print('[DEBUG] Saving token: ${response['accessToken'].substring(0, 20)}...');
      await ApiService.setToken(response['accessToken']);
      // Increased delay to ensure SharedPreferences write completes
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify token was saved
      final savedToken = await ApiService.getToken();
      print('[DEBUG] Retrieved token: ${savedToken?.substring(0, 20) ?? 'NULL'}...');
    }
    
    return response;
  }
  
  // ============= OTP Management =============
  
  static Future<Map<String, dynamic>> sendOTP(String phone, {String purpose = 'registration'}) async {
    final response = await ApiService.post(
      '/auth/send-otp',
      {'phone': phone, 'purpose': purpose},
      requiresAuth: false,
    );
    return response;
  }
  
  static Future<bool> verifyOTP(String phone, String code, {String purpose = 'registration'}) async {
    final response = await ApiService.post(
      '/auth/verify-otp',
      {'phone': phone, 'code': code, 'purpose': purpose},
      requiresAuth: false,
    );
    return response['verified'] == true;
  }
  
  static Future<void> logout() async {
    await ApiService.clearToken();
  }

  // ============= Estate Admin Registration =============
  
  static Future<Map<String, dynamic>> registerEstateAdmin({
    required Map<String, String> user,
    required Map<String, String> estate,
  }) async {
    final response = await ApiService.post(
      '/auth/register-estate-admin',
      {
        'user': user,
        'estate': estate,
      },
      requiresAuth: false,
    );
    return response;
  }

  // ============= Admin Role Transfer =============
  
  static Future<Map<String, dynamic>> transferAdmin(String newAdminUserId) async {
    final response = await ApiService.post(
      '/estate-admin/transfer-admin',
      {'newAdminUserId': newAdminUserId},
    );
    return response;
  }
  
  // ============= Dashboard Stats =============
  
  static Future<Map<String, dynamic>> getEstateStats() async {
    final response = await ApiService.get('/estates/stats');
    return response;
  }

  static Future<Map<String, dynamic>> getEstate(String id) async {
    final response = await ApiService.get('/estates/$id');
    return response;
  }

  static Future<Map<String, dynamic>> updateEstate(String id, Map<String, dynamic> data) async {
    final response = await ApiService.put('/estates/$id', data);
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
    await ApiService.delete('/users/$userId');
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
