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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: _parseUserRole(json['role'] as String),
      estateId: json['estateId'] as String,
      unitNumber: json['unitNumber'] as String?,
      isApproved: json['isApproved'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'estateId': estateId,
      'unitNumber': unitNumber,
      'isApproved': isApproved,
    };
  }

  static UserRole _parseUserRole(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return UserRole.SUPER_ADMIN;
      case 'ESTATE_ADMIN':
        return UserRole.ESTATE_ADMIN;
      case 'RESIDENT':
        return UserRole.RESIDENT;
      case 'SECURITY':
        return UserRole.SECURITY;
      default:
        return UserRole.RESIDENT;
    }
  }
}
