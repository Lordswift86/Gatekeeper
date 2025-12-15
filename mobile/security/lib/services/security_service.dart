import '../models/data_models.dart';

class SecurityService {
  // Singleton pattern
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // --- Seed Data ---
  List<User> _users = [
    User(id: 'u_1', name: 'Alice Admin', email: 'alice@sunset.com', role: UserRole.ESTATE_ADMIN, estateId: 'est_1', isApproved: true),
    User(id: 'u_2', name: 'Bob Resident', email: 'bob@sunset.com', role: UserRole.RESIDENT, estateId: 'est_1', unitNumber: '101', isApproved: true),
    User(id: 'u_3', name: 'Sam Security', email: 'sam@sunset.com', role: UserRole.SECURITY, estateId: 'est_1', isApproved: true),
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
    GuestPass(
        id: 'p_2',
        code: '54321',
        hostId: 'u_2',
        hostName: 'Bob Resident',
        hostUnit: '101',
        guestName: 'Jane Smith',
        status: PassStatus.CHECKED_IN,
        type: PassType.ONE_TIME,
        createdAt: DateTime.now().millisecondsSinceEpoch - 7200000,
        validUntil: DateTime.now().millisecondsSinceEpoch + 3600000 * 10,
        entryTime: DateTime.now().millisecondsSinceEpoch - 1800000,
    )
  ];

  List<LogEntry> _logs = [];
  List<EmergencyAlert> _alerts = [];
  List<IntercomSession> _calls = [];
  List<ChatMessage> _messages = [];

  // --- Methods ---

  Future<User?> login(String email) async {
    await Future.delayed(Duration(milliseconds: 500));
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }

  // Scanner Methods
  Future<Map<String, dynamic>> validateCode(String code, String estateId) async {
    await Future.delayed(Duration(milliseconds: 800));
    
    try {
      final pass = _passes.firstWhere((p) => p.code == code);
      
      final host = _users.firstWhere((u) => u.id == pass.hostId);
      if (host.estateId != estateId) {
        return {'success': false, 'message': 'Code belongs to a different estate.'};
      }

      if (pass.status == PassStatus.CANCELLED) {
        return {'success': false, 'message': 'Code has been cancelled by host.'};
      }

      if (pass.type == PassType.ONE_TIME || pass.type == PassType.DELIVERY) {
        if (pass.status == PassStatus.EXPIRED) {
          return {'success': false, 'message': 'Code expired.'};
        }
        if (pass.validUntil < DateTime.now().millisecondsSinceEpoch) {
          pass.status = PassStatus.EXPIRED;
          return {'success': false, 'message': 'Code expired.'};
        }
      }

      return {'success': true, 'pass': pass};
    } catch (e) {
      return {'success': false, 'message': 'Invalid Code'};
    }
  }

  void processEntry(String passId) {
    final index = _passes.indexWhere((p) => p.id == passId);
    if (index != -1) {
      _passes[index].status = PassStatus.CHECKED_IN;
      _passes[index].entryTime = DateTime.now().millisecondsSinceEpoch;

      final pass = _passes[index];
      final host = _users.firstWhere((u) => u.id == pass.hostId);
      
      _logs.add(LogEntry(
        id: 'l_${DateTime.now().millisecondsSinceEpoch}',
        estateId: host.estateId,
        guestName: pass.guestName,
        destination: 'Unit ${pass.hostUnit}',
        entryTime: DateTime.now().millisecondsSinceEpoch,
        type: 'DIGITAL',
        notes: pass.type == PassType.RECURRING ? 'Recurring Staff' : 'Guest',
      ));
    }
  }

  void processExit(String passId) {
    final index = _passes.indexWhere((p) => p.id == passId);
    if (index != -1) {
      final pass = _passes[index];
      PassStatus newStatus = pass.type == PassType.RECURRING ? PassStatus.ACTIVE : PassStatus.EXPIRED;
      
      _passes[index].status = newStatus;
      _passes[index].exitTime = DateTime.now().millisecondsSinceEpoch;

      // Update Log (Naive)
       final logIndex = _logs.lastIndexWhere((l) => l.guestName == pass.guestName && l.exitTime == null);
       if (logIndex != -1) {
         _logs[logIndex].exitTime = DateTime.now().millisecondsSinceEpoch;
       }
    }
  }

  // Delivery Methods
  List<GuestPass> getExpectedDeliveries(String estateId) {
    return _passes.where((p) {
      final host = _users.firstWhere((u) => u.id == p.hostId, orElse: () => User(id: '', name: '', email: '', role: UserRole.RESIDENT, estateId: '', isApproved: false));
      return host.estateId == estateId && p.type == PassType.DELIVERY && p.status == PassStatus.ACTIVE;
    }).toList();
  }

  void verifyDelivery(String passId, String plateNumber, {String? company}) {
    final index = _passes.indexWhere((p) => p.id == passId);
    if (index != -1) {
      _passes[index].status = PassStatus.CHECKED_IN;
      _passes[index].entryTime = DateTime.now().millisecondsSinceEpoch;
      _passes[index].plateNumber = plateNumber;
      if (company != null) _passes[index].deliveryCompany = company;

      // Log
      final pass = _passes[index];
       final host = _users.firstWhere((u) => u.id == pass.hostId);
      _logs.add(LogEntry(
          id: 'l_del_${DateTime.now().millisecondsSinceEpoch}',
          estateId: host.estateId,
          guestName: pass.guestName,
          destination: 'Unit ${pass.hostUnit}',
          entryTime: DateTime.now().millisecondsSinceEpoch,
          type: 'DIGITAL',
          notes: 'Delivery (${pass.deliveryCompany}) - Plate: $plateNumber'
      ));
    }
  }

  // Intercom
  List<User> getEstateResidents(String estateId) {
    return _users.where((u) => u.estateId == estateId && u.role == UserRole.RESIDENT).toList();
  }

  String initiateCall(String initiatorId, String residentId) {
    final initiator = _users.firstWhere((u) => u.id == initiatorId);
    final resident = _users.firstWhere((u) => u.id == residentId);
    
    final call = IntercomSession(
      id: 'call_${DateTime.now().millisecondsSinceEpoch}',
      estateId: resident.estateId,
      residentId: residentId,
      residentName: resident.name,
      securityId: initiatorId,
      initiator: 'SECURITY',
      status: CallStatus.RINGING,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _calls.add(call);
    return call.id;
  }

  List<ChatMessage> getMessages(String userId, String contactId) {
    return _messages.where((m) => 
      (m.fromId == userId && m.toId == contactId) || 
      (m.fromId == contactId && m.toId == userId)
    ).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void sendMessage(String fromId, String toId, String content) {
    _messages.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      fromId: fromId,
      toId: toId,
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      read: false
    ));
  }

  // Logs
  List<LogEntry> getEstateLogs(String estateId) {
     return _logs.where((l) => l.estateId == estateId).toList()..sort((a, b) => b.entryTime.compareTo(a.entryTime));
  }

  void addManualLogEntry(String estateId, String guestName, String destination, String? notes) {
    _logs.insert(0, LogEntry(
      id: 'ml_${DateTime.now().millisecondsSinceEpoch}',
      estateId: estateId,
      guestName: guestName,
      destination: destination,
      entryTime: DateTime.now().millisecondsSinceEpoch,
      type: 'MANUAL',
      notes: notes
    ));
  }

  // Alerts
  List<EmergencyAlert> getActiveAlerts(String estateId) {
    return _alerts.where((a) => a.estateId == estateId && a.status == 'ACTIVE').toList();
  }

  void resolveAlert(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index].status = 'RESOLVED';
    }
  }

  // Offline Sync Stub
  Future<void> syncOfflineActions(List<Map<String, dynamic>> actions) async {
    await Future.delayed(Duration(seconds: 1));
    for (var action in actions) {
       // Apply actions (Simplified)
       if (action['type'] == 'ENTRY') {
           processEntry(action['passId']);
       } else if (action['type'] == 'EXIT') {
           processExit(action['passId']);
       }
    }
  }
}
