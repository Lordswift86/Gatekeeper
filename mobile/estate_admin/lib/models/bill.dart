enum BillStatus {
  PAID,
  UNPAID
}

enum BillType {
  SERVICE_CHARGE,
  POWER,
  WASTE,
  WATER
}

class Bill {
  final String id;
  final String estateId;
  final String userId;
  final BillType type;
  final double amount;
  final int dueDate;
  BillStatus status;
  final int? paidAt;
  final String description;

  Bill({
    required this.id,
    required this.estateId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    required this.description,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      estateId: json['estateId'] as String,
      userId: json['userId'] as String,
      type: _parseBillType(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      dueDate: _parseTimestamp(json['dueDate']),
      status: _parseBillStatus(json['status'] as String),
      paidAt: json['paidAt'] != null ? _parseTimestamp(json['paidAt']) : null,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estateId': estateId,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'dueDate': dueDate,
      'status': status.name,
      'paidAt': paidAt,
      'description': description,
    };
  }

  static BillStatus _parseBillStatus(String status) {
    switch (status) {
      case 'PAID':
        return BillStatus.PAID;
      case 'UNPAID':
        return BillStatus.UNPAID;
      default:
        return BillStatus.UNPAID;
    }
  }

  static BillType _parseBillType(String type) {
    switch (type) {
      case 'SERVICE_CHARGE':
        return BillType.SERVICE_CHARGE;
      case 'POWER':
        return BillType.POWER;
      case 'WASTE':
        return BillType.WASTE;
      case 'WATER':
        return BillType.WATER;
      default:
        return BillType.SERVICE_CHARGE;
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
