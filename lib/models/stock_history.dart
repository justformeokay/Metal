/// Tracks every stock movement: restock, sale, manual adjustment, opname.
class StockHistory {
  final int? id;
  final String productId;
  final String productName;
  final String type; // restock, sale, adjustment, opname
  final int quantity; // positive = stock in, negative = stock out
  final int previousStock;
  final int newStock;
  final String notes;
  final DateTime createdAt;

  StockHistory({
    this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'productName': productName,
      'type': type,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockHistory.fromMap(Map<String, dynamic> map) {
    return StockHistory(
      id: map['id'] as int?,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toInt(),
      previousStock: (map['previousStock'] as num).toInt(),
      newStock: (map['newStock'] as num).toInt(),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Human-readable type label.
  String get typeLabel {
    switch (type) {
      case 'restock':
        return 'Restok';
      case 'sale':
        return 'Penjualan';
      case 'adjustment':
        return 'Penyesuaian';
      case 'opname':
        return 'Stock Opname';
      default:
        return type;
    }
  }
}
