import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

/// Controller for product & stock management.
class ProductController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  List<Product> get products {
    var filtered = _products;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategory != 'Semua') {
      filtered =
          filtered.where((p) => p.category == _selectedCategory).toList();
    }
    return filtered;
  }

  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock && !p.isOutOfStock).toList();

  List<Product> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  List<Product> get expiredProducts =>
      _products.where((p) => p.isExpired).toList();

  List<Product> get expiringSoonProducts =>
      _products.where((p) => p.isExpiringSoon).toList();

  /// Total number of stock alerts (low stock + out of stock + expired + expiring soon).
  int get totalAlerts =>
      lowStockProducts.length +
      outOfStockProducts.length +
      expiredProducts.length +
      expiringSoonProducts.length;

  bool get hasAlerts => totalAlerts > 0;

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['Semua', ...cats];
  }

  /// Load all products from the database.
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _db.getProducts();
    _isLoading = false;
    notifyListeners();
  }

  /// Clear cached data (called on logout).
  void clearData() {
    _products = [];
    _searchQuery = '';
    _selectedCategory = 'Semua';
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addProduct({
    required String name,
    required double costPrice,
    required double sellingPrice,
    required int stockQuantity,
    int minStock = 5,
    DateTime? expiryDate,
    String unit = 'pcs',
    String category = 'Umum',
  }) async {
    final product = Product(
      id: _uuid.v4(),
      name: name,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stockQuantity: stockQuantity,
      minStock: minStock,
      expiryDate: expiryDate,
      unit: unit,
      category: category,
    );
    await _db.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
    await loadProducts();
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    await _db.updateStock(productId, newQuantity);
    await loadProducts();
  }
}
