import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/expense.dart';
import '../models/business_profile.dart';
import '../models/calc_history.dart';
import '../models/member.dart';

/// SQLite database service — single source of truth for all local data.
///
/// Each user gets their own database file: `labaku_user_{userId}.db`
/// This ensures data isolation between different user accounts.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static int? _currentUserId;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Switch to a different user's database.
  /// Closes the current DB (if open) and opens the user-specific one.
  Future<void> switchUser(int userId) async {
    if (_currentUserId == userId && _database != null) return;

    // Close existing database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _currentUserId = userId;
    _database = await _initDatabase();
  }

  /// Close the current database (used on logout).
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _currentUserId = null;
  }

  String get _dbFileName {
    if (_currentUserId != null) {
      return 'labaku_user_$_currentUserId.db';
    }
    return 'labaku.db';
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbFileName);

    return openDatabase(
      path,
      version: 10,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Create all tables on first run.
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        stockQuantity INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pcs',
        category TEXT NOT NULL DEFAULT 'Umum',
        minStock INTEGER NOT NULL DEFAULT 5,
        expiryDate TEXT,
        barcode TEXT,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_barcode ON products(barcode) WHERE barcode IS NOT NULL');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        totalAmount REAL NOT NULL,
        totalCost REAL NOT NULL,
        totalDiscount REAL NOT NULL DEFAULT 0,
        amountPaid REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        notes TEXT,
        paymentMethod TEXT NOT NULL DEFAULT "Tunai",
        transferBank TEXT,
        transferAccountNumber TEXT,
        memberId TEXT,
        memberDiscountApplied REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        costPrice REAL NOT NULL,
        discountPercent REAL NOT NULL DEFAULT 0,
        discountAmount REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (transactionId) REFERENCES transactions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE business_profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        storeName TEXT NOT NULL DEFAULT 'Toko Saya',
        address TEXT,
        phone TEXT,
        tagline TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE calc_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        expression TEXT NOT NULL,
        result TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        discountPercent REAL NOT NULL DEFAULT 0,
        memberSince TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active'
      )
    ''');

    // Insert default profile
    await db.insert('business_profile', {
      'id': 1,
      'storeName': 'Toko Saya',
      'address': '',
      'phone': '',
      'tagline': 'Terima kasih atas kunjungan Anda!',
    });
  }

  /// Upgrade tables when schema version increases.
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN minStock INTEGER NOT NULL DEFAULT 5');
      await db.execute('ALTER TABLE products ADD COLUMN expiryDate TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_barcode ON products(barcode) WHERE barcode IS NOT NULL');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS calc_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          expression TEXT NOT NULL,
          result TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE transactions ADD COLUMN totalDiscount REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE transaction_items ADD COLUMN discountPercent REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE transaction_items ADD COLUMN discountAmount REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE transactions ADD COLUMN amountPaid REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE transactions ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT "Tunai"');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE transactions ADD COLUMN transferBank TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN transferAccountNumber TEXT');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS members (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT,
          discountPercent REAL NOT NULL DEFAULT 0,
          memberSince TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'active'
        )
      ''');
      await db.execute('ALTER TABLE transactions ADD COLUMN memberId TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN memberDiscountApplied REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 10) {
      await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT');
    }
  }

  // ─── Products ───────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProduct(String id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    final db = await database;
    await db.update('products', {'stockQuantity': newQuantity},
        where: 'id = ?', whereArgs: [productId]);
  }

  /// Look up a product by its barcode value.
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query('products',
        where: 'barcode = ?', whereArgs: [barcode]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> getTotalStockItems() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(stockQuantity) as total FROM products');
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final maps = await db.query('products',
        where: 'stockQuantity <= minStock',
        orderBy: 'stockQuantity ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getExpiringProducts({int withinDays = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().add(Duration(days: withinDays)).toIso8601String();
    final maps = await db.query('products',
        where: 'expiryDate IS NOT NULL AND expiryDate <= ?',
        whereArgs: [cutoff],
        orderBy: 'expiryDate ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  // ─── Members ────────────────────────────────────────────────

  Future<List<Member>> getMembers() async {
    final db = await database;
    final maps = await db.query('members', orderBy: 'name ASC');
    return maps.map((m) => Member.fromMap(m)).toList();
  }

  Future<List<Member>> searchMembers(String query) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: "(name LIKE ? OR phone LIKE ?) AND status = 'active'",
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Member.fromMap(m)).toList();
  }

  Future<Member?> getMemberById(String id) async {
    final db = await database;
    final maps = await db.query('members', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Member.fromMap(maps.first);
  }

  Future<void> insertMember(Member member) async {
    final db = await database;
    await db.insert('members', member.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMember(Member member) async {
    final db = await database;
    await db.update('members', member.toMap(),
        where: 'id = ?', whereArgs: [member.id]);
  }

  Future<void> deleteMember(String id) async {
    final db = await database;
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getMemberTransactionCount(String memberId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE memberId = ?',
      [memberId],
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<double> getMemberTotalSpent(String memberId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(totalAmount), 0) as total FROM transactions WHERE memberId = ?',
      [memberId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ─── Transactions ──────────────────────────────────────────

  Future<void> insertTransaction(SalesTransaction tx) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap());
      for (final item in tx.items) {
        await txn.insert('transaction_items', {
          ...item.toMap(),
          'transactionId': tx.id,
        });
        // Reduce stock
        await txn.rawUpdate(
          'UPDATE products SET stockQuantity = stockQuantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }

  Future<List<SalesTransaction>> getTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;

    String? where;
    List<Object>? whereArgs;

    if (from != null && to != null) {
      where = 'date >= ? AND date <= ?';
      whereArgs = [from.toIso8601String(), to.toIso8601String()];
    }

    final txMaps = await db.query('transactions',
        where: where, whereArgs: whereArgs, orderBy: 'date DESC');

    List<SalesTransaction> result = [];
    for (final txMap in txMaps) {
      final itemMaps = await db.query('transaction_items',
          where: 'transactionId = ?', whereArgs: [txMap['id']]);
      final items = itemMaps.map((m) => TransactionItem.fromMap(m)).toList();
      result.add(SalesTransaction.fromMap(txMap, items));
    }
    return result;
  }

  Future<List<SalesTransaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getTransactions(from: start, to: end);
  }

  Future<double> getSalesTotal({DateTime? from, DateTime? to}) async {
    final db = await database;
    String query = 'SELECT SUM(totalAmount) as total FROM transactions';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE date >= ? AND date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getCostTotal({DateTime? from, DateTime? to}) async {
    final db = await database;
    String query = 'SELECT SUM(totalCost) as total FROM transactions';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE date >= ? AND date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Top-selling products for a date range.
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? from,
    DateTime? to,
    int limit = 5,
  }) async {
    final db = await database;
    String query = '''
      SELECT ti.productName, SUM(ti.quantity) as totalQty, SUM(ti.quantity * ti.unitPrice) as totalRevenue
      FROM transaction_items ti
      JOIN transactions t ON ti.transactionId = t.id
    ''';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE t.date >= ? AND t.date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    query += ' GROUP BY ti.productId ORDER BY totalQty DESC LIMIT ?';
    args = [...?args, limit];
    return db.rawQuery(query, args);
  }

  // ─── Expenses ───────────────────────────────────────────────

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update('expenses', expense.toMap(),
        where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpenses({DateTime? from, DateTime? to}) async {
    final db = await database;
    String? where;
    List<Object>? whereArgs;
    if (from != null && to != null) {
      where = 'date >= ? AND date <= ?';
      whereArgs = [from.toIso8601String(), to.toIso8601String()];
    }
    final maps = await db.query('expenses',
        where: where, whereArgs: whereArgs, orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<double> getExpenseTotal({DateTime? from, DateTime? to}) async {
    final db = await database;
    String query = 'SELECT SUM(amount) as total FROM expenses';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE date >= ? AND date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Expense breakdown by category for a date range.
  Future<List<Map<String, dynamic>>> getExpenseBreakdown({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    String query =
        'SELECT category, SUM(amount) as total FROM expenses';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE date >= ? AND date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    query += ' GROUP BY category ORDER BY total DESC';
    return db.rawQuery(query, args);
  }

  // ─── Business Profile ──────────────────────────────────────

  Future<BusinessProfile> getBusinessProfile() async {
    final db = await database;
    final maps = await db.query('business_profile', where: 'id = 1');
    if (maps.isEmpty) return BusinessProfile();
    return BusinessProfile.fromMap(maps.first);
  }

  Future<void> updateBusinessProfile(BusinessProfile profile) async {
    final db = await database;
    await db.update('business_profile', profile.toMap(), where: 'id = 1');
  }

  // ─── Database Status ────────────────────────────────────────

  /// Check if local database has no user data (fresh install / reinstall).
  Future<bool> isLocalDatabaseEmpty() async {
    final db = await database;
    final productCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    ) ?? 0;
    final txCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM transactions'),
    ) ?? 0;
    return productCount == 0 && txCount == 0;
  }

  // ─── Calculator History ────────────────────────────────────

  Future<List<CalcHistory>> getCalcHistory() async {
    final db = await database;
    final maps = await db.query('calc_history', orderBy: 'id DESC', limit: 20);
    return maps.map((m) => CalcHistory.fromMap(m)).toList();
  }

  Future<void> insertCalcHistory(CalcHistory entry) async {
    final db = await database;
    await db.insert('calc_history', entry.toMap());
    // Keep only latest 20
    await db.rawDelete('''
      DELETE FROM calc_history WHERE id NOT IN (
        SELECT id FROM calc_history ORDER BY id DESC LIMIT 20
      )
    ''');
  }

  Future<void> clearCalcHistory() async {
    final db = await database;
    await db.delete('calc_history');
  }

  // ─── Backup & Restore ──────────────────────────────────────

  /// Export all data as a map for JSON serialization.
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final products = await db.query('products');
    final transactions = await db.query('transactions');
    final transactionItems = await db.query('transaction_items');
    final expenses = await db.query('expenses');
    final profile = await db.query('business_profile');

    return {
      'products': products,
      'transactions': transactions,
      'transactionItems': transactionItems,
      'expenses': expenses,
      'businessProfile': profile,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Restore data from a previously exported map.
  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('transaction_items');
      await txn.delete('transactions');
      await txn.delete('expenses');
      await txn.delete('products');

      // Import products
      for (final p in (data['products'] as List)) {
        await txn.insert('products', Map<String, dynamic>.from(p));
      }
      // Import transactions
      for (final t in (data['transactions'] as List)) {
        await txn.insert('transactions', Map<String, dynamic>.from(t));
      }
      // Import transaction items
      for (final ti in (data['transactionItems'] as List)) {
        final map = Map<String, dynamic>.from(ti);
        map.remove('id'); // auto-increment
        await txn.insert('transaction_items', map);
      }
      // Import expenses
      for (final e in (data['expenses'] as List)) {
        await txn.insert('expenses', Map<String, dynamic>.from(e));
      }
      // Import profile
      if ((data['businessProfile'] as List).isNotEmpty) {
        final profileData =
            Map<String, dynamic>.from((data['businessProfile'] as List).first);
        await txn.update('business_profile', profileData, where: 'id = 1');
      }
    });
  }

  /// Get database file path for direct file backup.
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbFileName);
  }

  // ─── Advanced Analytics ────────────────────────────────────

  /// Daily sales totals for a date range (for trend line charts).
  Future<List<Map<String, dynamic>>> getDailySales({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    return db.rawQuery('''
      SELECT DATE(date) as day,
             SUM(totalAmount) as sales,
             SUM(totalCost) as cost,
             COUNT(*) as txCount
      FROM transactions
      WHERE date >= ? AND date <= ?
      GROUP BY DATE(date)
      ORDER BY day ASC
    ''', [from.toIso8601String(), to.toIso8601String()]);
  }

  /// Hourly distribution of transactions (for peak hours analysis).
  Future<List<Map<String, dynamic>>> getHourlySalesDistribution({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    String query = '''
      SELECT CAST(strftime('%H', date) AS INTEGER) as hour,
             SUM(totalAmount) as sales,
             COUNT(*) as txCount
      FROM transactions
    ''';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE date >= ? AND date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    query += ' GROUP BY hour ORDER BY hour ASC';
    return db.rawQuery(query, args);
  }

  /// Top products with full margin data for a date range.
  Future<List<Map<String, dynamic>>> getProductAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    String query = '''
      SELECT ti.productId, ti.productName,
             SUM(ti.quantity) as totalQty,
             SUM(ti.quantity * ti.unitPrice) as totalRevenue,
             SUM(ti.quantity * ti.costPrice) as totalCost,
             SUM(ti.quantity * (ti.unitPrice - ti.costPrice)) as totalProfit,
             COUNT(DISTINCT ti.transactionId) as txCount
      FROM transaction_items ti
      JOIN transactions t ON ti.transactionId = t.id
    ''';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE t.date >= ? AND t.date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    query += ' GROUP BY ti.productId ORDER BY totalRevenue DESC';
    return db.rawQuery(query, args);
  }

  /// Category-level sales breakdown for a date range.
  Future<List<Map<String, dynamic>>> getCategorySales({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    String query = '''
      SELECT p.category,
             SUM(ti.quantity) as totalQty,
             SUM(ti.quantity * ti.unitPrice) as totalRevenue,
             SUM(ti.quantity * (ti.unitPrice - ti.costPrice)) as totalProfit
      FROM transaction_items ti
      JOIN transactions t ON ti.transactionId = t.id
      JOIN products p ON ti.productId = p.id
    ''';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE t.date >= ? AND t.date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    query += ' GROUP BY p.category ORDER BY totalRevenue DESC';
    return db.rawQuery(query, args);
  }

  /// Transaction count and average transaction value.
  Future<Map<String, dynamic>> getTransactionStats({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    String query = '''
      SELECT COUNT(*) as txCount,
             COALESCE(AVG(totalAmount), 0) as avgValue,
             COALESCE(MAX(totalAmount), 0) as maxValue,
             COALESCE(MIN(totalAmount), 0) as minValue
      FROM transactions
    ''';
    List<Object>? args;
    if (from != null && to != null) {
      query += ' WHERE date >= ? AND date <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    final result = await db.rawQuery(query, args);
    return result.first;
  }
}
