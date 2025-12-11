enum UserRole {
  SUPER_ADMIN,
  ESTATE_ADMIN,
  RESIDENT,
  SECURITY
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
