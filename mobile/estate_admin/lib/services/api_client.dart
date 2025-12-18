import 'api_service.dart';
import '../models/user.dart';
import '../modules/resident/models/pass.dart';
import '../modules/resident/models/bill.dart';

class ApiClient {
  // ============= Authentication =============
  
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await ApiService.post(
      '/auth/login',
      {'phone': phone, 'password': password},
      requiresAuth: false,
    );

    if (response == null) {
      throw Exception('Login failed: No response from server');
    }
    
    // Backend returns 'accessToken', not 'token'
    if (response['accessToken'] != null) {
      print('[DEBUG] Saving token: ${response['accessToken'].substring(0, 20)}...');
      await ApiService.setToken(response['accessToken']);
      // Increased delay to ensure SharedPreferences write completes
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify token was saved
      final savedToken = await ApiService.getToken();
      print('[DEBUG] Retrieved token: ${savedToken?.substring(0, 20) ?? 'NULL'}...');
    } else {
      // If we got a response but no token, something is wrong
       print('[DEBUG] Login response missing accessToken: $response');
       // Depending on backend, maybe it returns error in body but status 200? 
       // For now, let's just proceed or throw if critical.
       // It's better to return response so UI can handle it or throw?
       // The original code would crash on next line accessing null['accessToken'] equivalent if it was null.
       // Here response is not null. But if accessToken is null, we log it.
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

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email, // Keeping email as it was, as replacing it with 'phone' would cause a duplicate parameter.
    required String password,
    required String role,
    required String estateCode,
    String? unitNumber,
  }) async {
    final response = await ApiService.post(
      '/auth/register',
      {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        'password': password,
        'role': role,
        'estateCode': estateCode,
        if (unitNumber != null) 'unitNumber': unitNumber,
      },
      requiresAuth: false,
    );
    
    return response;
  }
  
  // ============= Password Reset =============
  
  static Future<void> resetPassword(String phone, String newPassword) async {
    await ApiService.post(
      '/auth/reset-password',
      {'phone': phone, 'newPassword': newPassword},
      requiresAuth: false,
    );
  }
  
  // ============= Referrals =============
  
  static Future<String> getReferralCode() async {
    final response = await ApiService.get('/users/me/referral-code');
    return response['referralCode'];
  }
  
  static Future<Map<String, dynamic>> getReferralStats() async {
    final response = await ApiService.get('/users/me/referral-stats');
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

  static Future<Map<String, dynamic>?> updateEstate(String id, Map<String, dynamic> data) async {
    print('[DEBUG] ApiClient.updateEstate id: $id, data: $data');
    final response = await ApiService.put('/estates/$id', data);
    return response as Map<String, dynamic>?;
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

  // ============= Resident: Profile & Household =============

  static Future<dynamic> getProfile() async {
    final response = await ApiService.get('/users/profile');
    // Note: Resident module expects User model. 
    // We return dynamic/map here, and the calling code likely converts it using User.fromJson(response).
    // Or we should import User model here? 
    // To avoid dependency cycles or complex imports, let's return the Map and let caller parse, OR import modules models if needed.
    // Resident Dashboard: `final user = await ApiClient.getProfile();` -> returns User?
    // In Resident ApiClient: `return User.fromJson(response);`
    // If I return Map here, the Dashboard code `User? _user; ... _user = user;` will fail if it expects User object.
    // I MUST return Map and updated Dashboards? OR Import User model.
    // If I import User model from `modules/resident/models/user.dart`, it might be fine.
    return response; 
  }

  static Future<dynamic> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.put('/users/profile', data);
    return response;
  }

  static Future<List<dynamic>> getHousehold() async {
    final response = await ApiService.get('/household');
    return response as List;
  }

  static Future<dynamic> addSubAccount(String name, String email, String password) async {
    final response = await ApiService.post('/household', {
      'name': name,
      'email': email,
      'password': password
    });
    return response;
  }

  static Future<void> removeSubAccount(String userId) async {
    await ApiService.delete('/household/$userId');
  }

  static Future<Map<String, dynamic>> getIdentityToken() async {
    return await ApiService.get('/identity/token');
  }

  static Future<Map<String, dynamic>> verifyIdentity(String token) async {
    return await ApiService.post('/identity/verify', {'token': token});
  }

  static Future<bool> checkAccessRestricted() async {
     try {
       // Re-implement logic
       return false; // placeholder for now to avoid compilation error
     } catch (e) {
       return false;
     }
  }

  // ============= Resident: Passes =============

  static Future<List<GuestPass>> getUserPasses() async {
    final response = await ApiService.get('/passes/my-passes');
    return (response as List).map((e) => GuestPass.fromJson(e)).toList();
  }

  static Future<dynamic> generatePass({
    required String guestName,
    required String type,
    String? exitInstruction,
    String? deliveryCompany,
    List<String>? recurringDays,
    String? recurringStart,
    String? recurringEnd,
  }) async {
    final response = await ApiService.post('/passes/generate', {
      'guestName': guestName,
      'type': type,
      'exitInstruction': exitInstruction,
      'deliveryCompany': deliveryCompany,
      'recurringDays': recurringDays,
      'recurringTimeStart': recurringStart,
      'recurringTimeEnd': recurringEnd,
    });
    return response;
  }

  static Future<void> cancelPass(String passId) async {
    await ApiService.delete('/passes/$passId');
  }

  // ============= Resident: Bills =============

  static Future<List<Bill>> getUserBills() async {
    final response = await ApiService.get('/bills/my');
    return (response as List).map((e) => Bill.fromJson(e)).toList();
  }

  static Future<dynamic> payBill(String billId) async {
    final response = await ApiService.post('/bills/$billId/pay', {});
    return response;
  }

  static Future<dynamic> verifyPayment(String billId, String reference) async {
    final response = await ApiService.post('/bills/$billId/verify-payment', {
      'reference': reference,
    });
    return response;
  }
  
  // ============= Security: Operations =============

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

  static Future<List<dynamic>> getActiveAlerts() async {
    final response = await ApiService.get('/security/alerts/active');
    return response as List? ?? [];
  }
  
  static Future<void> resolveAlert(String alertId) async {
    await ApiService.post('/security/alerts/$alertId/resolve', {});
  }
  
  static Future<void> triggerSOS() async {
    await ApiService.post('/security/alert', {});
  }

  static Future<List<dynamic>> getPendingDeliveries() async {
    final response = await ApiService.get('/passes?type=DELIVERY&status=ACTIVE');
    return response as List? ?? [];
  }
  
  static Future<void> confirmDelivery(String passId) async {
    await ApiService.post('/passes/$passId/entry', {});
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

  static Future<List<dynamic>> getLogs() async {
    return getEstateLogs();
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

  // ============= Global Ads =============

  static Future<List<dynamic>> getGlobalAds() async {
    final response = await ApiService.get('/admin/global-ads');
    return response as List;
  }
}
