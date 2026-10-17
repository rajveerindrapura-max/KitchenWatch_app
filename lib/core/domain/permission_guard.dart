enum UserRole {
  owner,
  manager,
  employee;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }
}

class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException([this.message = 'Permission denied']);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

class PermissionGuard {
  PermissionGuard._();

  static bool canViewStockValue(UserRole role) {
    return role == UserRole.owner || role == UserRole.manager;
  }

  static bool canAddItem(UserRole role) {
    return role == UserRole.owner || role == UserRole.manager;
  }

  static bool canEditMinStock(UserRole role) {
    return role == UserRole.owner || role == UserRole.manager;
  }

  static bool canRecordIncoming(UserRole role) {
    return role == UserRole.owner || role == UserRole.manager;
  }

  static bool canRecordAdjustment(UserRole role) {
    return role == UserRole.owner || role == UserRole.manager;
  }

  static bool canTransfer(UserRole role) {
    return role == UserRole.owner || role == UserRole.manager;
  }

  static bool canRecordUsageAndWaste(UserRole role) {
    return true; // Owner, Manager and Employee can all record usage and wastage
  }

  static bool canManageOutlets(UserRole role) {
    return role == UserRole.owner;
  }

  static bool canManageTeam(UserRole role) {
    return role == UserRole.owner;
  }

  static void verifyViewStockValue(UserRole role) {
    if (!canViewStockValue(role)) {
      throw const PermissionDeniedException('Employees cannot view stock valuation');
    }
  }

  static void verifyAddItem(UserRole role) {
    if (!canAddItem(role)) {
      throw const PermissionDeniedException('Only owners and managers can add new items');
    }
  }

  static void verifyEditMinStock(UserRole role) {
    if (!canEditMinStock(role)) {
      throw const PermissionDeniedException('Only owners and managers can edit minimum stock levels');
    }
  }

  static void verifyRecordIncoming(UserRole role) {
    if (!canRecordIncoming(role)) {
      throw const PermissionDeniedException('Only owners and managers can record incoming stock');
    }
  }

  static void verifyRecordAdjustment(UserRole role) {
    if (!canRecordAdjustment(role)) {
      throw const PermissionDeniedException('Only owners and managers can record stock adjustments');
    }
  }

  static void verifyTransfer(UserRole role) {
    if (!canTransfer(role)) {
      throw const PermissionDeniedException('Only owners and managers can transfer stock between outlets');
    }
  }

  static void verifyManageOutlets(UserRole role) {
    if (!canManageOutlets(role)) {
      throw const PermissionDeniedException('Only owners can manage outlets');
    }
  }

  static void verifyManageTeam(UserRole role) {
    if (!canManageTeam(role)) {
      throw const PermissionDeniedException('Only owners can manage team members');
    }
  }
}
