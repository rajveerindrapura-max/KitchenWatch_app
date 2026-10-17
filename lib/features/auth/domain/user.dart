import '../../../core/domain/permission_guard.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final List<String> assignedOutletIds;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.assignedOutletIds = const [],
    this.isActive = true,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager;
  bool get isEmployee => role == UserRole.employee;

  bool canAccessOutlet(String? outletId) {
    if (outletId == null) {
      // "All outlets" view is only available to owners
      return isOwner;
    }
    if (isOwner) return true;
    return assignedOutletIds.contains(outletId);
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    List<String>? assignedOutletIds,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedOutletIds: assignedOutletIds ?? this.assignedOutletIds,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'assignedOutletIds': assignedOutletIds,
      'isActive': isActive,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: UserRole.values.firstWhere((r) => r.name == json['role']),
      assignedOutletIds: (json['assignedOutletIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ role.hashCode;
}
