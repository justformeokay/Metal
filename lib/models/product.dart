/// Product model representing items sold by the business.
class Product {
  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final String unit; // pcs, kg, liter, etc.
  final String category;
  final int minStock; // minimum stock threshold per product
  final DateTime? expiryDate; // optional expiration date
  final String? barcode; // barcode / QR code value
  final String? imagePath; // local image file path (optional)
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Discount fields ──────────────────────────────────────
  final bool discountEnabled;
  final String? discountLabel;   // e.g. "Flash Sale", "Promo Lebaran"
  final double discountPercent;  // 0–100
  final DateTime? discountStartDate;
  final DateTime? discountEndDate;

  Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.unit = 'pcs',
    this.category = 'Umum',
    this.minStock = 5,
    this.expiryDate,
    this.barcode,
    this.imagePath,
    this.discountEnabled = false,
    this.discountLabel,
    this.discountPercent = 0,
    this.discountStartDate,
    this.discountEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Whether stock is below the per-product minimum threshold.
  bool get isLowStock => stockQuantity <= minStock;

  /// Whether stock is zero.
  bool get isOutOfStock => stockQuantity <= 0;

  /// Whether the product is expired.
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  /// Whether the product will expire within the next 7 days.
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 7)));

  /// Days until expiry (negative = already expired).
  int? get daysUntilExpiry => expiryDate?.difference(DateTime.now()).inDays;

  /// Profit margin per unit.
  double get profitPerUnit => sellingPrice - costPrice;

  /// Profit margin percentage.
  double get marginPercent =>
      costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

  /// Whether the discount is currently active (enabled + within date window).
  bool get isDiscountActive {
    if (!discountEnabled || discountPercent <= 0) return false;
    final now = DateTime.now();
    if (discountStartDate != null && now.isBefore(discountStartDate!)) {
      return false;
    }
    if (discountEndDate != null &&
        now.isAfter(discountEndDate!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  /// Final price after discount (if active).
  double get discountedPrice {
    if (!isDiscountActive) return sellingPrice;
    return sellingPrice * (1 - discountPercent / 100);
  }

  /// Discount amount in Rupiah.
  double get discountAmountValue {
    if (!isDiscountActive) return 0;
    return sellingPrice * (discountPercent / 100);
  }

  Product copyWith({
    String? id,
    String? name,
    double? costPrice,
    double? sellingPrice,
    int? stockQuantity,
    String? unit,
    String? category,
    int? minStock,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? barcode,
    bool clearBarcode = false,
    String? imagePath,
    bool clearImagePath = false,
    bool? discountEnabled,
    String? discountLabel,
    bool clearDiscountLabel = false,
    double? discountPercent,
    DateTime? discountStartDate,
    bool clearDiscountStartDate = false,
    DateTime? discountEndDate,
    bool clearDiscountEndDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      minStock: minStock ?? this.minStock,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      discountEnabled: discountEnabled ?? this.discountEnabled,
      discountLabel: clearDiscountLabel ? null : (discountLabel ?? this.discountLabel),
      discountPercent: discountPercent ?? this.discountPercent,
      discountStartDate: clearDiscountStartDate ? null : (discountStartDate ?? this.discountStartDate),
      discountEndDate: clearDiscountEndDate ? null : (discountEndDate ?? this.discountEndDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'category': category,
      'minStock': minStock,
      'expiryDate': expiryDate?.toIso8601String(),
      'barcode': barcode,
      'imagePath': imagePath,
      'discountEnabled': discountEnabled ? 1 : 0,
      'discountLabel': discountLabel,
      'discountPercent': discountPercent,
      'discountStartDate': discountStartDate?.toIso8601String(),
      'discountEndDate': discountEndDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      costPrice: (map['costPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      stockQuantity: (map['stockQuantity'] as num).toInt(),
      unit: map['unit'] as String? ?? 'pcs',
      category: map['category'] as String? ?? 'Umum',
      minStock: (map['minStock'] as num?)?.toInt() ?? 5,
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'] as String)
          : null,
      barcode: map['barcode'] as String?,
      imagePath: map['imagePath'] as String?,
      discountEnabled: (map['discountEnabled'] as int? ?? 0) == 1,
      discountLabel: map['discountLabel'] as String?,
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
      discountStartDate: map['discountStartDate'] != null
          ? DateTime.tryParse(map['discountStartDate'] as String)
          : null,
      discountEndDate: map['discountEndDate'] != null
          ? DateTime.tryParse(map['discountEndDate'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}


