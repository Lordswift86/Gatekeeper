import 'api_service.dart';
import '../models/user.dart';
import '../models/pass.dart';
import '../models/bill.dart';

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
      'user': User.fromJson(response['user']),
      'token': response['token'],
    };
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
    // Note: This would need to be implemented on the backend
    // For now, we can use a workaround if the endpoint doesn't exist
    throw UnimplementedError('Cancel pass endpoint not yet implemented');
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
}
