/// A member/customer of the store for loyalty and discount tracking.
class Member {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final double discountPercent;
  final DateTime memberSince;
  final String status; // active, inactive

  Member({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.discountPercent = 0,
    DateTime? memberSince,
    this.status = 'active',
  }) : memberSince = memberSince ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'discountPercent': discountPercent,
      'memberSince': memberSince.toIso8601String(),
      'status': status,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
      memberSince: DateTime.parse(map['memberSince'] as String),
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'discount_percent': discountPercent,
      'member_since': memberSince.toIso8601String(),
      'status': status,
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      memberSince: json['member_since'] != null
          ? DateTime.parse(json['member_since'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'active',
    );
  }
}
