/// Expense record for business costs.
class Expense {
  final String id;
  final String name;
  final String category; // Bahan Baku, Listrik, Sewa, Kemasan, Lainnya
  final double amount;
  final DateTime date;
  final String notes;

  Expense({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    DateTime? date,
    this.notes = '',
  }) : date = date ?? DateTime.now();

  Expense copyWith({
    String? id,
    String? name,
    String? category,
    double? amount,
    DateTime? date,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String? ?? '',
    );
  }
}

/// Predefined expense categories.
class ExpenseCategories {
  static const List<String> all = [
    'Bahan Baku',
    'Listrik & Air',
    'Sewa',
    'Kemasan',
    'Transportasi',
    'Gaji',
    'Peralatan',
    'Lainnya',
  ];
}
