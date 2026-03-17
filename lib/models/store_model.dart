/// Store model matching API response structure.
class StoreModel {
  final int id;
  final int userId;
  final String storeName;
  final String? businessType;
  final String? logoUrl;
  final String? phone;
  final String? address;
  final String? description;
  final String? createdAt;

  StoreModel({
    required this.id,
    required this.userId,
    required this.storeName,
    this.businessType,
    this.logoUrl,
    this.phone,
    this.address,
    this.description,
    this.createdAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      storeName: json['store_name'] as String,
      businessType: json['business_type'] as String?,
      logoUrl: json['logo_url'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store_name': storeName,
      'business_type': businessType,
      'logo_url': logoUrl,
      'phone': phone,
      'address': address,
      'description': description,
      'created_at': createdAt,
    };
  }
}
