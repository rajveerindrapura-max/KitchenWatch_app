class Outlet {
  final String id;
  final String name;
  final String address;
  final String phone;
  final bool isActive;

  const Outlet({
    required this.id,
    required this.name,
    required this.address,
    this.phone = '',
    this.isActive = true,
  });

  Outlet copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) {
    return Outlet(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'isActive': isActive,
    };
  }

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Outlet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
