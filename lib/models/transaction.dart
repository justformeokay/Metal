/// A single item within a sales transaction.
class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double costPrice;
  final double discountPercent;
  final double discountAmount;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
  });

  /// Price per item after discount.
  double get effectivePrice {
    double price = unitPrice;
    if (discountPercent > 0) {
      price -= price * discountPercent / 100;
    }
    if (discountAmount > 0) {
      price -= discountAmount;
    }
    return price < 0 ? 0 : price;
  }

  /// Whether this item has any discount.
  bool get hasDiscount => discountPercent > 0 || discountAmount > 0;

  /// Total discount for this line item.
  double get totalDiscount => (unitPrice - effectivePrice) * quantity;

  /// Total selling price for this line item.
  double get subtotal => quantity * effectivePrice;

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
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A sales transaction (receipt).
class SalesTransaction {
  final String id;
  final List<TransactionItem> items;
  final double totalAmount;
  final double totalCost;
  final double totalDiscount;
  final double amountPaid;
  final DateTime date;
  final String? notes;
  final String paymentMethod; // Cash, QRIS, Gopay, OVO, Dana, Transfer

  SalesTransaction({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.totalCost,
    this.totalDiscount = 0,
    this.amountPaid = 0,
    DateTime? date,
    this.notes,
    this.paymentMethod = 'Tunai',
  }) : date = date ?? DateTime.now();

  /// Change from payment.
  double get change => (amountPaid - totalAmount).clamp(0, double.infinity);

  /// Gross profit for this transaction.
  double get profit => totalAmount - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'totalDiscount': totalDiscount,
      'amountPaid': amountPaid,
      'date': date.toIso8601String(),
      'notes': notes ?? '',
      'paymentMethod': paymentMethod,
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
      totalDiscount: (map['totalDiscount'] as num?)?.toDouble() ?? 0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      paymentMethod: map['paymentMethod'] as String? ?? 'Tunai',
    );
  }
}
