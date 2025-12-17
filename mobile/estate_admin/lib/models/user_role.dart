enum UserRole {
  estateAdmin,
  resident,
  security,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.estateAdmin:
        return 'Estate Admin';
      case UserRole.resident:
        return 'Resident';
      case UserRole.security:
        return 'Security';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.estateAdmin:
        return 'ESTATE_ADMIN';
      case UserRole.resident:
        return 'RESIDENT';
      case UserRole.security:
        return 'SECURITY';
    }
  }
}
