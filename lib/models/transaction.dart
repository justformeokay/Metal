/// A single item within a sales transaction.
class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double costPrice;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
  });

  /// Total selling price for this line item.
  double get subtotal => quantity * unitPrice;

  /// Total cost for this line item.
  double get totalCost => quantity * costPrice;

  /// Profit for this line item.
  double get profit => subtotal - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
    );
  }
}

/// A sales transaction (receipt).
class SalesTransaction {
  final String id;
  final List<TransactionItem> items;
  final double totalAmount;
  final double totalCost;
  final DateTime date;
  final String? notes;

  SalesTransaction({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.totalCost,
    DateTime? date,
    this.notes,
  }) : date = date ?? DateTime.now();

  /// Gross profit for this transaction.
  double get profit => totalAmount - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'date': date.toIso8601String(),
      'notes': notes ?? '',
    };
  }

  factory SalesTransaction.fromMap(
    Map<String, dynamic> map,
    List<TransactionItem> items,
  ) {
    return SalesTransaction(
      id: map['id'] as String,
      items: items,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
