enum PassStatus {
  ACTIVE,
  CHECKED_IN,
  EXPIRED,
  CANCELLED
}

enum PassType {
  ONE_TIME,
  RECURRING,
  DELIVERY
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
  final List<String>? recurringDays;
  final String? recurringTimeStart;
  final String? recurringTimeEnd;
  final int createdAt;
  final int validUntil;
  final int? entryTime;
  final int? exitTime;
  final String? deliveryCompany;

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
    this.recurringDays,
    this.recurringTimeStart,
    this.recurringTimeEnd,
    required this.createdAt,
    required this.validUntil,
    this.entryTime,
    this.exitTime,
    this.deliveryCompany,
  });
}
