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

  factory GuestPass.fromJson(Map<String, dynamic> json) {
    return GuestPass(
      id: json['id'] as String,
      code: json['code'] as String,
      hostId: json['hostId'] as String,
      hostName: json['hostName'] ?? json['hostUnit'] ?? '',
      hostUnit: json['hostUnit'] as String? ?? '',
      guestName: json['guestName'] as String,
      exitInstruction: json['exitInstruction'] as String?,
      status: _parsePassStatus(json['status'] as String),
      type: _parsePassType(json['type'] as String),
      recurringDays: json['recurringDays'] != null
          ? (json['recurringDays'] as String).split(',')
          : null,
      recurringTimeStart: json['recurringTimeStart'] as String?,
      recurringTimeEnd: json['recurringTimeEnd'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      validUntil: _parseTimestamp(json['validUntil']),
      entryTime: json['entryTime'] != null ? _parseTimestamp(json['entryTime']) : null,
      exitTime: json['exitTime'] != null ? _parseTimestamp(json['exitTime']) : null,
      deliveryCompany: json['deliveryCompany'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'hostId': hostId,
      'guestName': guestName,
      'exitInstruction': exitInstruction,
      'status': status.name,
      'type': type.name,
      'recurringDays': recurringDays?.join(','),
      'recurringTimeStart': recurringTimeStart,
      'recurringTimeEnd': recurringTimeEnd,
      'deliveryCompany': deliveryCompany,
      'hostUnit': hostUnit,
      'validFrom': DateTime.fromMillisecondsSinceEpoch(createdAt).toIso8601String(),
      'validUntil': DateTime.fromMillisecondsSinceEpoch(validUntil).toIso8601String(),
    };
  }

  static PassStatus _parsePassStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return PassStatus.ACTIVE;
      case 'CHECKED_IN':
        return PassStatus.CHECKED_IN;
      case 'EXPIRED':
        return PassStatus.EXPIRED;
      case 'CANCELLED':
        return PassStatus.CANCELLED;
      default:
        return PassStatus.ACTIVE;
    }
  }

  static PassType _parsePassType(String type) {
    switch (type) {
      case 'ONE_TIME':
        return PassType.ONE_TIME;
      case 'RECURRING':
        return PassType.RECURRING;
      case 'DELIVERY':
        return PassType.DELIVERY;
      default:
        return PassType.ONE_TIME;
    }
  }

  static int _parseTimestamp(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      try {
        return DateTime.parse(value).millisecondsSinceEpoch;
      } catch (_) {
        return DateTime.now().millisecondsSinceEpoch;
      }
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}
