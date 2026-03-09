/// Store model matching API response structure.
class StoreModel {
  final int id;
  final int userId;
  final String storeName;
  final String? phone;
  final String? address;
  final String? createdAt;

  StoreModel({
    required this.id,
    required this.userId,
    required this.storeName,
    this.phone,
    this.address,
    this.createdAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      storeName: json['store_name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store_name': storeName,
      'phone': phone,
      'address': address,
      'created_at': createdAt,
    };
  }
}
