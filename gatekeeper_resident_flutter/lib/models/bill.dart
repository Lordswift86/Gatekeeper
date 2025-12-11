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
}
