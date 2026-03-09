import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

/// Controller for expense tracking.
class ExpenseController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  /// Load expenses, optionally filtered by date range.
  Future<void> loadExpenses({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();
    _expenses = await _db.getExpenses(from: from, to: to);
    _isLoading = false;
    notifyListeners();
  }

  /// Clear cached data (called on logout).
  void clearData() {
    _expenses = [];
    notifyListeners();
  }

  Future<void> addExpense({
    required String name,
    required String category,
    required double amount,
    DateTime? date,
    String notes = '',
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      name: name,
      category: category,
      amount: amount,
      date: date,
      notes: notes,
    );
    await _db.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);
    await loadExpenses();
  }

  /// Get today's expense total.
  Future<double> getTodayExpenses() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _db.getExpenseTotal(from: start, to: end);
  }

  /// Get expense total for a date range.
  Future<double> getExpenseTotal({DateTime? from, DateTime? to}) async {
    return _db.getExpenseTotal(from: from, to: to);
  }

  /// Get expense breakdown by category.
  Future<List<Map<String, dynamic>>> getExpenseBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    return _db.getExpenseBreakdown(from: from, to: to);
  }
}
