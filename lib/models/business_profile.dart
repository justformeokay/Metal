/// Business profile information.
class BusinessProfile {
  final String storeName;
  final String address;
  final String phone;
  final String? tagline;

  BusinessProfile({
    this.storeName = 'Toko Saya',
    this.address = '',
    this.phone = '',
    this.tagline,
  });

  BusinessProfile copyWith({
    String? storeName,
    String? address,
    String? phone,
    String? tagline,
  }) {
    return BusinessProfile(
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      tagline: tagline ?? this.tagline,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'address': address,
      'phone': phone,
      'tagline': tagline ?? '',
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      storeName: map['storeName'] as String? ?? 'Toko Saya',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      tagline: map['tagline'] as String?,
    );
  }
}
