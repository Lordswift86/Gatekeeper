import 'package:gatekeeper_estate_admin/modules/resident/models/user.dart';
import 'package:gatekeeper_estate_admin/modules/resident/models/pass.dart';
import 'package:gatekeeper_estate_admin/modules/resident/models/bill.dart';
import 'dart:math';

class MockService {
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal();

  User? currentUser;

  final List<User> _users = [
    User(
      id: 'u_2',
      name: 'Bob Resident',
      email: 'bob@sunset.com',
      role: UserRole.RESIDENT,
      estateId: 'est_1',
      unitNumber: '101',
      isApproved: true,
    ),
  ];

  List<GuestPass> _passes = [
    GuestPass(
      id: 'p_1',
      code: '12345',
      hostId: 'u_2',
      hostName: 'Bob Resident',
      hostUnit: '101',
      guestName: 'John Doe',
      status: PassStatus.ACTIVE,
      type: PassType.ONE_TIME,
      createdAt: DateTime.now().millisecondsSinceEpoch - 3600000,
      validUntil: DateTime.now().millisecondsSinceEpoch + 3600000 * 11,
      exitInstruction: 'Leaving with a heavy box.',
    ),
  ];

  List<Bill> _bills = [
    Bill(
      id: 'b_1',
      estateId: 'est_1',
      userId: 'u_2',
      type: BillType.SERVICE_CHARGE,
      amount: 150.00,
      dueDate: DateTime.now().millisecondsSinceEpoch - (86400000 * 35),
      status: BillStatus.UNPAID,
      description: 'September 2023 Service Charge',
    ),
  ];

  Future<User?> login(String email) async {
    await Future.delayed(Duration(milliseconds: 500));
    try {
      final user = _users.firstWhere((u) => u.email == email);
      currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  List<GuestPass> getUserPasses(String userId) {
    return _passes.where((p) => p.hostId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Bill> getUserBills(String userId) {
    return _bills.where((b) => b.userId == userId).toList();
  }

  GuestPass generatePass({
    required String userId,
    required String guestName,
    String? exitInstruction,
    required PassType type,
    List<String>? recurringDays,
    String? recurringStart,
    String? recurringEnd,
    String? deliveryCompany,
  }) {
    final user = _users.firstWhere((u) => u.id == userId);
    
    int validUntil = DateTime.now().millisecondsSinceEpoch;
    if (type == PassType.ONE_TIME) validUntil += 3600000 * 12;
    else if (type == PassType.RECURRING) validUntil += 3600000 * 24 * 30;
    else if (type == PassType.DELIVERY) validUntil += 1800000;

    final newPass = GuestPass(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      code: (10000 + Random().nextInt(90000)).toString(),
      hostId: userId,
      hostName: user.name,
      hostUnit: user.unitNumber ?? 'N/A',
      guestName: type == PassType.DELIVERY ? (deliveryCompany ?? 'Delivery') : guestName,
      deliveryCompany: deliveryCompany,
      exitInstruction: exitInstruction,
      status: PassStatus.ACTIVE,
      type: type,
      recurringDays: recurringDays,
      recurringTimeStart: recurringStart,
      recurringTimeEnd: recurringEnd,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      validUntil: validUntil,
    );

    _passes.insert(0, newPass);
    return newPass;
  }

  void cancelPass(String passId) {
    final index = _passes.indexWhere((p) => p.id == passId);
    if (index != -1) {
      _passes[index].status = PassStatus.CANCELLED;
    }
  }

  Future<void> payBill(String billId) async {
    await Future.delayed(Duration(milliseconds: 800));
    final index = _bills.indexWhere((b) => b.id == billId);
    if (index != -1) {
      _bills[index].status = BillStatus.PAID;
    }
  }

  bool checkAccessRestricted(String userId) {
    final overdueLimit = DateTime.now().millisecondsSinceEpoch - (86400000 * 30);
    return _bills.any((b) => b.userId == userId && b.status == BillStatus.UNPAID && b.dueDate < overdueLimit);
  }
}
