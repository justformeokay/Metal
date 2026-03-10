import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

/// Cart item used in POS before finalizing a transaction.
class CartItem {
  final Product product;
  int quantity;
  double discountPercent; // 0-100
  double discountAmount;  // flat Rp discount per item

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discountPercent = 0,
    this.discountAmount = 0,
  });

  /// Price per item after discount.
  double get effectivePrice {
    double price = product.sellingPrice;
    if (discountPercent > 0) {
      price -= price * discountPercent / 100;
    }
    if (discountAmount > 0) {
      price -= discountAmount;
    }
    return price < 0 ? 0 : price;
  }

  /// Total discount for this line item.
  double get totalDiscount => (product.sellingPrice - effectivePrice) * quantity;

  /// Whether this item has any discount applied.
  bool get hasDiscount => discountPercent > 0 || discountAmount > 0;

  double get subtotal => quantity * effectivePrice;
  double get totalCost => quantity * product.costPrice;
}

/// Controller for the POS / sales system.
class TransactionController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  // Cart state
  final List<CartItem> _cart = [];
  List<SalesTransaction> _recentTransactions = [];
  bool _isLoading = false;

  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  List<SalesTransaction> get recentTransactions => _recentTransactions;

  double get cartTotal =>
      _cart.fold(0, (sum, item) => sum + item.subtotal);

  double get cartCostTotal =>
      _cart.fold(0, (sum, item) => sum + item.totalCost);

  double get cartDiscountTotal =>
      _cart.fold(0, (sum, item) => sum + item.totalDiscount);

  int get cartItemCount =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  /// Add product to cart or increment if already exists.
  void addToCart(Product product) {
    final existingIndex =
        _cart.indexWhere((c) => c.product.id == product.id);
    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity < product.stockQuantity) {
        _cart[existingIndex].quantity++;
      }
    } else {
      if (product.stockQuantity > 0) {
        _cart.add(CartItem(product: product));
      }
    }
    notifyListeners();
  }

  /// Update quantity of a cart item.
  void updateCartQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else if (quantity <= _cart[index].product.stockQuantity) {
      _cart[index].quantity = quantity;
    }
    notifyListeners();
  }

  /// Update discount of a cart item.
  void updateCartDiscount(int index, {double percent = 0, double amount = 0}) {
    if (index >= 0 && index < _cart.length) {
      _cart[index].discountPercent = percent;
      _cart[index].discountAmount = amount;
      notifyListeners();
    }
  }

  /// Remove item from cart.
  void removeFromCart(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  /// Clear all items from cart.
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Finalize the sale — save transaction and reduce stock.
  Future<SalesTransaction?> completeSale({String? notes, double amountPaid = 0}) async {
    if (_cart.isEmpty) return null;

    final items = _cart
        .map((c) => TransactionItem(
              productId: c.product.id,
              productName: c.product.name,
              quantity: c.quantity,
              unitPrice: c.product.sellingPrice,
              costPrice: c.product.costPrice,
              discountPercent: c.discountPercent,
              discountAmount: c.discountAmount,
            ))
        .toList();

    final transaction = SalesTransaction(
      id: _uuid.v4(),
      items: items,
      totalAmount: cartTotal,
      totalCost: cartCostTotal,
      totalDiscount: cartDiscountTotal,
      amountPaid: amountPaid,
      notes: notes,
    );

    await _db.insertTransaction(transaction);
    _cart.clear();
    notifyListeners();
    return transaction;
  }

  /// Load recent transactions.
  Future<void> loadRecentTransactions({int limit = 10}) async {
    _isLoading = true;
    notifyListeners();
    final all = await _db.getTransactions();
    _recentTransactions = all.take(limit).toList();
    _isLoading = false;
    notifyListeners();
  }

  /// Clear cached data (called on logout).
  void clearData() {
    _cart.clear();
    _recentTransactions = [];
    notifyListeners();
  }

  /// Get today's sales total.
  Future<double> getTodaySales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _db.getSalesTotal(from: start, to: end);
  }

  /// Get today's COGS total.
  Future<double> getTodayCost() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _db.getCostTotal(from: start, to: end);
  }

  /// Get transactions for a date range.
  Future<List<SalesTransaction>> getTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    return _db.getTransactions(from: from, to: to);
  }

  /// Get sales total for a date range.
  Future<double> getSalesTotal({DateTime? from, DateTime? to}) async {
    return _db.getSalesTotal(from: from, to: to);
  }

  /// Get cost total for a date range.
  Future<double> getCostTotal({DateTime? from, DateTime? to}) async {
    return _db.getCostTotal(from: from, to: to);
  }

  /// Get top selling products.
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? from,
    DateTime? to,
    int limit = 5,
  }) async {
    return _db.getTopSellingProducts(from: from, to: to, limit: limit);
  }
}
