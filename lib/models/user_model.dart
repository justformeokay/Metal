/// User model matching API response structure.
///
/// The backend `users` table only stores [id] and [email] for auth.
/// [name] and [phone] are optional — they come from the `stores` table later.
class UserModel {
  final int id;
  final String email;
  final String name;
  final String phone;

  UserModel({
    required this.id,
    required this.email,
    this.name = '',
    this.phone = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
    };
  }
}
