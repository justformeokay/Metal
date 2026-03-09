import 'database_service.dart';

/// Processed analytics data models and computation service.
class AnalyticsService {
  static final DatabaseService _db = DatabaseService();

  /// Get full analytics data for a given period.
  static Future<AnalyticsData> getAnalytics({
    required DateTime from,
    required DateTime to,
  }) async {
    final results = await Future.wait([
      _db.getDailySales(from: from, to: to),
      _db.getProductAnalytics(from: from, to: to),
      _db.getTransactionStats(from: from, to: to),
      _db.getHourlySalesDistribution(from: from, to: to),
      _db.getCategorySales(from: from, to: to),
    ]);

    final dailySales = (results[0] as List<Map<String, dynamic>>)
        .map((m) => DailySalesData(
              date: DateTime.parse(m['day'] as String),
              sales: (m['sales'] as num).toDouble(),
              cost: (m['cost'] as num).toDouble(),
              txCount: (m['txCount'] as num).toInt(),
            ))
        .toList();

    final productAnalytics = (results[1] as List<Map<String, dynamic>>)
        .map((m) => ProductAnalyticsData(
              productId: m['productId'] as String,
              productName: m['productName'] as String,
              totalQty: (m['totalQty'] as num).toInt(),
              totalRevenue: (m['totalRevenue'] as num).toDouble(),
              totalCost: (m['totalCost'] as num).toDouble(),
              totalProfit: (m['totalProfit'] as num).toDouble(),
              txCount: (m['txCount'] as num).toInt(),
            ))
        .toList();

    final txStats = results[2] as Map<String, dynamic>;

    final hourlySales = (results[3] as List<Map<String, dynamic>>)
        .map((m) => HourlySalesData(
              hour: (m['hour'] as num).toInt(),
              sales: (m['sales'] as num).toDouble(),
              txCount: (m['txCount'] as num).toInt(),
            ))
        .toList();

    final categorySales = (results[4] as List<Map<String, dynamic>>)
        .map((m) => CategorySalesData(
              category: m['category'] as String,
              totalQty: (m['totalQty'] as num).toInt(),
              totalRevenue: (m['totalRevenue'] as num).toDouble(),
              totalProfit: (m['totalProfit'] as num).toDouble(),
            ))
        .toList();

    return AnalyticsData(
      dailySales: dailySales,
      products: productAnalytics,
      txCount: (txStats['txCount'] as num).toInt(),
      avgTransactionValue: (txStats['avgValue'] as num).toDouble(),
      maxTransactionValue: (txStats['maxValue'] as num).toDouble(),
      hourlySales: hourlySales,
      categorySales: categorySales,
    );
  }

  /// Compare two periods and return growth metrics.
  static Future<PeriodComparison> comparePeriods({
    required DateTime currentFrom,
    required DateTime currentTo,
    required DateTime previousFrom,
    required DateTime previousTo,
  }) async {
    final results = await Future.wait([
      _db.getSalesTotal(from: currentFrom, to: currentTo),
      _db.getSalesTotal(from: previousFrom, to: previousTo),
      _db.getCostTotal(from: currentFrom, to: currentTo),
      _db.getCostTotal(from: previousFrom, to: previousTo),
      _db.getExpenseTotal(from: currentFrom, to: currentTo),
      _db.getExpenseTotal(from: previousFrom, to: previousTo),
      _db.getTransactionStats(from: currentFrom, to: currentTo),
      _db.getTransactionStats(from: previousFrom, to: previousTo),
    ]);

    final curSales = results[0] as double;
    final prevSales = results[1] as double;
    final curCost = results[2] as double;
    final prevCost = results[3] as double;
    final curExpense = results[4] as double;
    final prevExpense = results[5] as double;
    final curStats = results[6] as Map<String, dynamic>;
    final prevStats = results[7] as Map<String, dynamic>;

    final curProfit = curSales - curCost - curExpense;
    final prevProfit = prevSales - prevCost - prevExpense;

    return PeriodComparison(
      currentSales: curSales,
      previousSales: prevSales,
      currentProfit: curProfit,
      previousProfit: prevProfit,
      currentExpenses: curExpense,
      previousExpenses: prevExpense,
      currentTxCount: (curStats['txCount'] as num).toInt(),
      previousTxCount: (prevStats['txCount'] as num).toInt(),
      currentAvgTx: (curStats['avgValue'] as num).toDouble(),
      previousAvgTx: (prevStats['avgValue'] as num).toDouble(),
    );
  }

  /// Simple linear trend prediction for next N days based on daily sales data.
  static List<DailySalesData> predictSales(
      List<DailySalesData> history, int daysAhead) {
    if (history.length < 2) return [];

    // Simple linear regression on sales
    final n = history.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += history[i].sales;
      sumXY += i * history[i].sales;
      sumX2 += i * i;
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final lastDate = history.last.date;
    return List.generate(daysAhead, (i) {
      final x = n + i;
      final predictedSales = (intercept + slope * x).clamp(0.0, double.infinity);
      return DailySalesData(
        date: lastDate.add(Duration(days: i + 1)),
        sales: predictedSales,
        cost: 0,
        txCount: 0,
        isPrediction: true,
      );
    });
  }
}

// ─── Data Models ──────────────────────────────────────────────

class AnalyticsData {
  final List<DailySalesData> dailySales;
  final List<ProductAnalyticsData> products;
  final int txCount;
  final double avgTransactionValue;
  final double maxTransactionValue;
  final List<HourlySalesData> hourlySales;
  final List<CategorySalesData> categorySales;

  AnalyticsData({
    required this.dailySales,
    required this.products,
    required this.txCount,
    required this.avgTransactionValue,
    required this.maxTransactionValue,
    required this.hourlySales,
    required this.categorySales,
  });

  double get totalSales =>
      dailySales.fold(0.0, (sum, d) => sum + d.sales);
  double get totalCost =>
      dailySales.fold(0.0, (sum, d) => sum + d.cost);
  double get totalProfit => totalSales - totalCost;

  int get peakHour {
    if (hourlySales.isEmpty) return 0;
    return hourlySales.reduce((a, b) => a.txCount > b.txCount ? a : b).hour;
  }
}

class DailySalesData {
  final DateTime date;
  final double sales;
  final double cost;
  final int txCount;
  final bool isPrediction;

  DailySalesData({
    required this.date,
    required this.sales,
    required this.cost,
    required this.txCount,
    this.isPrediction = false,
  });

  double get profit => sales - cost;
}

class ProductAnalyticsData {
  final String productId;
  final String productName;
  final int totalQty;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final int txCount;

  ProductAnalyticsData({
    required this.productId,
    required this.productName,
    required this.totalQty,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.txCount,
  });

  double get marginPercent =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
}

class HourlySalesData {
  final int hour;
  final double sales;
  final int txCount;

  HourlySalesData({
    required this.hour,
    required this.sales,
    required this.txCount,
  });
}

class CategorySalesData {
  final String category;
  final int totalQty;
  final double totalRevenue;
  final double totalProfit;

  CategorySalesData({
    required this.category,
    required this.totalQty,
    required this.totalRevenue,
    required this.totalProfit,
  });

  double get marginPercent =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
}

class PeriodComparison {
  final double currentSales;
  final double previousSales;
  final double currentProfit;
  final double previousProfit;
  final double currentExpenses;
  final double previousExpenses;
  final int currentTxCount;
  final int previousTxCount;
  final double currentAvgTx;
  final double previousAvgTx;

  PeriodComparison({
    required this.currentSales,
    required this.previousSales,
    required this.currentProfit,
    required this.previousProfit,
    required this.currentExpenses,
    required this.previousExpenses,
    required this.currentTxCount,
    required this.previousTxCount,
    required this.currentAvgTx,
    required this.previousAvgTx,
  });

  double get salesGrowth =>
      previousSales > 0 ? ((currentSales - previousSales) / previousSales) * 100 : 0;
  double get profitGrowth =>
      previousProfit != 0 ? ((currentProfit - previousProfit) / previousProfit.abs()) * 100 : 0;
  double get expenseGrowth =>
      previousExpenses > 0 ? ((currentExpenses - previousExpenses) / previousExpenses) * 100 : 0;
  double get txCountGrowth =>
      previousTxCount > 0 ? ((currentTxCount - previousTxCount) / previousTxCount) * 100 : 0;
}
