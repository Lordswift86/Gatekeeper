
enum UserRole {
  SUPER_ADMIN,
  ESTATE_ADMIN,
  RESIDENT,
  SECURITY,
}

enum PassStatus {
  ACTIVE,
  CHECKED_IN,
  EXPIRED,
  CANCELLED,
}

enum PassType {
  ONE_TIME,
  RECURRING,
  DELIVERY,
}

enum CallStatus {
  RINGING,
  CONNECTED,
  ENDED,
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String estateId;
  final String? unitNumber;
  final bool isApproved;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.estateId,
    this.unitNumber,
    required this.isApproved,
  });
}

class GuestPass {
  final String id;
  final String code;
  final String hostId;
  final String hostName;
  final String hostUnit;
  final String guestName;
  final String? exitInstruction;
  PassStatus status;
  final PassType type;
  final int createdAt;
  final int validUntil;
  int? entryTime;
  int? exitTime;
  
  // Delivery
  String? plateNumber;
  String? deliveryCompany;

  GuestPass({
    required this.id,
    required this.code,
    required this.hostId,
    required this.hostName,
    required this.hostUnit,
    required this.guestName,
    this.exitInstruction,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.validUntil,
    this.entryTime,
    this.exitTime,
    this.plateNumber,
    this.deliveryCompany,
  });
}

class LogEntry {
  final String id;
  final String estateId;
  final String guestName;
  final String destination;
  final int entryTime;
  int? exitTime;
  final String type; // 'MANUAL' | 'DIGITAL'
  final String? notes;

  LogEntry({
    required this.id,
    required this.estateId,
    required this.guestName,
    required this.destination,
    required this.entryTime,
    this.exitTime,
    required this.type,
    this.notes,
  });
}

class EmergencyAlert {
  final String id;
  final String estateId;
  final String residentId;
  final String unitNumber;
  String status; // 'ACTIVE' | 'RESOLVED'
  final int timestamp;

  EmergencyAlert({
    required this.id,
    required this.estateId,
    required this.residentId,
    required this.unitNumber,
    required this.status,
    required this.timestamp,
  });
}

class IntercomSession {
  final String id;
  final String estateId;
  final String residentId;
  final String residentName;
  final String? securityId;
  final String initiator; // 'SECURITY' | 'RESIDENT'
  CallStatus status;
  final int timestamp;

  IntercomSession({
    required this.id,
    required this.estateId,
    required this.residentId,
    required this.residentName,
    this.securityId,
    required this.initiator,
    required this.status,
    required this.timestamp,
  });
}

class ChatMessage {
  final String id;
  final String fromId;
  final String toId;
  final String content;
  final int timestamp;
  final bool read;

  ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.content,
    required this.timestamp,
    required this.read,
  });
}
