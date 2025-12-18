import 'api_service.dart';
import '../models/user.dart';
import '../models/pass.dart';
import '../models/bill.dart';

class ApiClient {
  // ============= Authentication =============
  
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await ApiService.post(
      '/auth/login',
      {'phone': phone, 'password': password},
      requiresAuth: false,
    );
    
    // Store token
    if (response['token'] != null) {
      await ApiService.setToken(response['token']);
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
  
  static Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String estateCode,
    String? unitNumber,
  }) async {
    final response = await ApiService.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'estateCode': estateCode,
        'unitNumber': unitNumber,
      },
      requiresAuth: false,
    );
    
    return User.fromJson(response['user']);
  }
  
  // ============= Guest Passes =============
  
  static Future<List<GuestPass>> getUserPasses() async {
    final response = await ApiService.get('/passes/my-passes');
    return (response as List)
        .map((json) => GuestPass.fromJson(json))
        .toList();
  }
  
  static Future<GuestPass> generatePass({
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
    
    return GuestPass.fromJson(response);
  }
  
  static Future<void> cancelPass(String passId) async {
    await ApiService.delete('/passes/$passId');
  }
  
  static Future<void> triggerSOS() async {
    await ApiService.post('/security/alert', {});
  }
  
  // ============= Bills =============
  
  static Future<List<Bill>> getUserBills() async {
    final response = await ApiService.get('/bills/my');
    return (response as List)
        .map((json) => Bill.fromJson(json))
        .toList();
  }
  
  static Future<Bill> payBill(String billId) async {
    final response = await ApiService.post('/bills/$billId/pay', {});
    return Bill.fromJson(response);
  }
  
  static Future<Bill> verifyPayment(String billId, String reference) async {
    final response = await ApiService.post('/bills/$billId/verify-payment', {
      'reference': reference,
    });
    return Bill.fromJson(response);
  }
  
  // ============= User Profile =============
  
  static Future<User> getProfile() async {
    final response = await ApiService.get('/users/profile');
    return User.fromJson(response);
  }
  
  static Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.put('/users/profile', data);
    return User.fromJson(response);
  }
  
  // ============= Utility =============
  
  static Future<bool> checkAccessRestricted() async {
    // Check if user has overdue bills
    try {
      final bills = await getUserBills();
      final overdueLimit = DateTime.now().millisecondsSinceEpoch - (86400000 * 30);
      return bills.any((b) => 
        b.status == BillStatus.UNPAID && b.dueDate < overdueLimit
      );
    } catch (e) {
      return false;
    }
  }
  // ============ Identity ============
  
  static Future<Map<String, dynamic>> getIdentityToken() async {
    return await ApiService.get('/identity/token');
  }

  // ============ Household ============

  static Future<List<User>> getHousehold() async {
    final response = await ApiService.get('/household');
    return (response as List).map((json) => User.fromJson(json)).toList();
  }

  static Future<User> addSubAccount(String name, String email, String password) async {
    final response = await ApiService.post('/household', {
      'name': name,
      'email': email,
      'password': password
    });
    return User.fromJson(response);
  }

  static Future<void> removeSubAccount(String userId) async {
    await ApiService.delete('/household/$userId');
  }

  // ============= Global Ads =============

  static Future<List<dynamic>> getGlobalAds() async {
    final response = await ApiService.get('/admin/global-ads');
    return response as List;
  }

  static Future<void> recordAdImpression(String adId) async {
    try {
      await ApiService.post('/admin/global-ads/$adId/impression', {});
    } catch (e) {
      print('Failed to record impression: $e');
    }
  }

  static Future<void> recordAdClick(String adId) async {
    try {
      await ApiService.post('/admin/global-ads/$adId/click', {});
    } catch (e) {
      print('Failed to record click: $e');
    }
  }
}
