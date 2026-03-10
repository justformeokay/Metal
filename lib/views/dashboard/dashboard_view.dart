import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/expense_controller.dart';
import '../../controllers/product_controller.dart';
import '../../services/analytics_service.dart';
import '../../services/cloud_backup_service.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/transaction_list_item.dart';
import '../../widgets/empty_state.dart';
import '../products/stock_alerts_view.dart';
import '../calculator/standard_calculator_view.dart';
import '../calculator/finance_calculator_view.dart';
import 'transaction_detail_sheet.dart';

/// Main dashboard screen — overview of today's business metrics.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  double _todaySales = 0;
  double _todayExpenses = 0;
  double _todayCost = 0;
  int _totalStock = 0;
  bool _isLoading = true;
  bool _backupCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final txCtrl = context.read<TransactionController>();
    final expCtrl = context.read<ExpenseController>();
    final prodCtrl = context.read<ProductController>();

    try {
      // Load ONLY critical metrics first
      // These are lightweight queries that just calculate totals
      await Future.wait([
        prodCtrl.loadProducts(), // Load products for stock count
      ]);

      // Get today's metrics (simple aggregates)
      final sales = await txCtrl.getTodaySales();
      final cost = await txCtrl.getTodayCost();
      final expenses = await expCtrl.getTodayExpenses();
      final stock = prodCtrl.allProducts
          .fold<int>(0, (sum, p) => sum + p.stockQuantity);

      if (mounted) {
        setState(() {
          _todaySales = sales;
          _todayCost = cost;
          _todayExpenses = expenses;
          _totalStock = stock;
          _isLoading = false;
        });
      }

      // Load transactions and expenses in BACKGROUND after UI displays
      // These don't need to complete before showing the dashboard
      if (mounted) {
        txCtrl.loadRecentTransactions();
        expCtrl.loadExpenses();
      }

      // Check for server backup if local DB is empty (reinstall scenario)
      if (!_backupCheckDone && mounted) {
        _backupCheckDone = true;
        _checkBackupRecommendation();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check if local DB is empty and server has a backup → show restore dialog.
  Future<void> _checkBackupRecommendation() async {
    try {
      final db = DatabaseService();
      final isEmpty = await db.isLocalDatabaseEmpty();
      if (!isEmpty || !mounted) return;

      final backupInfo = await CloudBackupService.checkServerBackupAvailable();
      if (backupInfo == null || !mounted) return;

      _showRestoreRecommendationDialog(backupInfo);
    } catch (_) {
      // Silently ignore — not critical
    }
  }

  /// Show a dialog recommending the user to restore from server backup.
  void _showRestoreRecommendationDialog(Map<String, dynamic> backupInfo) {
    final createdAt = backupInfo['created_at'] as String? ?? '';
    final backupSize = backupInfo['backup_size'] as num? ?? 0;
    final backupType = backupInfo['backup_type'] as String? ?? 'manual';
    final sizeMB = (backupSize / 1024 / 1024).toStringAsFixed(2);

    // Format date
    String formattedDate = createdAt;
    final parsed = DateTime.tryParse(createdAt);
    if (parsed != null) {
      formattedDate = formatDate(parsed);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cloud_download_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Data Backup Ditemukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Kami menemukan data backup Anda di server. Apakah Anda ingin memulihkan data dari backup terakhir?',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? Theme.of(ctx).cardColor
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _backupInfoRow(Icons.calendar_today_rounded, 'Tanggal', formattedDate),
                  const SizedBox(height: 8),
                  _backupInfoRow(Icons.storage_rounded, 'Ukuran', '$sizeMB MB'),
                  const SizedBox(height: 8),
                  _backupInfoRow(
                    Icons.backup_rounded,
                    'Tipe',
                    backupType == 'auto' ? 'Otomatis' : 'Manual',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _performRestore();
              },
              icon: const Icon(Icons.restore_rounded, size: 20),
              label: const Text('Pulihkan Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Lewati'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backupInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Perform the actual restore from server.
  Future<void> _performRestore() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingIndicator(size: 48),
            SizedBox(height: 16),
            Text(
              'Memulihkan data dari server...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );

    final result = await CloudBackupService.downloadAndRestore();

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.accentColor : AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      if (result.success) {
        // Reload dashboard data after restore
        _loadData();
      }
    }
  }

  double get _todayProfit => _todaySales - _todayExpenses - _todayCost;

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final txCtrl = context.watch<TransactionController>();
    final prodCtrl = context.watch<ProductController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/final.png',
              height: 32,
            ),
            Text(
              'Halo, ${authCtrl.user?.name ?? 'User'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              formatDate(DateTime.now()),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(
              message: 'Memuat dashboard...',
              indicatorSize: 60,
            )
          : Center(
              child: SizedBox(
                width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.5),
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                  // ─── Top Metric Cards ──────────────────────
                  // Sales Card (Full width)
                  _buildMetricCard(
                    backgroundColor: const Color(0xFF2563EB),
                    title: 'Penjualan Hari Ini',
                    value: formatCurrency(_todaySales),
                    icon: Icons.trending_up_rounded,
                    subtitle: 'Pertumbuhan bisnis',
                  ),
                  const SizedBox(height: 12),

                  // Two-column cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactMetricCard(
                          backgroundColor: const Color(0xFF10B981),
                          title: 'Keuntungan',
                          value: formatCurrency(_todayProfit),
                          icon: Icons.account_balance_wallet_rounded,
                          isProfit: _todayProfit >= 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactMetricCard(
                          backgroundColor: const Color(0xFFF59E0B),
                          title: 'Pengeluaran',
                          value: formatCurrency(_todayExpenses),
                          icon: Icons.money_off_rounded,
                          isProfit: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stock & Performance
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactMetricCard(
                          backgroundColor: const Color(0xFF8B5CF6),
                          title: 'Total Stok',
                          value: '$_totalStock',
                          subtitle: 'item',
                          icon: Icons.shopping_bag_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactMetricCard(
                          backgroundColor: const Color(0xFF06B6D4),
                          title: 'Transaksi Hari Ini',
                          value: '${txCtrl.recentTransactions.where((t) => _isToday(t.date)).length}',
                          subtitle: 'penjualan',
                          icon: Icons.receipt_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Quick Access Tools ────────────────────
                  _sectionTitle('Tools'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildToolCard(
                          icon: Icons.calculate_rounded,
                          color: const Color(0xFFFF9F0A),
                          title: 'Kalkulator',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StandardCalculatorView(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildToolCard(
                          icon: Icons.payments_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Keuangan',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FinanceCalculatorView(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Stock & Expiry Alerts ─────────────────
                  if (prodCtrl.hasAlerts) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Peringatan Inventori'),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StockAlertsView(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Alert Cards Grid
                    Column(
                      children: [
                        // Row 1: Out of Stock & Low Stock
                        Row(
                          children: [
                            if (prodCtrl.outOfStockProducts.isNotEmpty) ...[
                              _buildAlertCard(
                                icon: Icons.remove_shopping_cart_rounded,
                                color: AppTheme.dangerColor,
                                bgColor: AppTheme.dangerColor,
                                count: prodCtrl.outOfStockProducts.length,
                                label: 'Stok Habis',
                                subtitle: 'Perlu pembelian ulang',
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (prodCtrl.lowStockProducts.isNotEmpty)
                              _buildAlertCard(
                                icon: Icons.inventory_2_rounded,
                                color: AppTheme.warningColor,
                                bgColor: AppTheme.warningColor,
                                count: prodCtrl.lowStockProducts.length,
                                label: 'Stok Menipis',
                                subtitle: 'Kurang dari minimum',
                              ),
                            if (prodCtrl.outOfStockProducts.isEmpty &&
                                prodCtrl.lowStockProducts.isEmpty)
                              const Spacer(),
                          ],
                        ),
                        if ((prodCtrl.outOfStockProducts.isNotEmpty ||
                                prodCtrl.lowStockProducts.isNotEmpty) &&
                            (prodCtrl.expiredProducts.isNotEmpty ||
                                prodCtrl.expiringSoonProducts.isNotEmpty))
                          const SizedBox(height: 12),
                        // Row 2: Expired & Expiring Soon
                        Row(
                          children: [
                            if (prodCtrl.expiredProducts.isNotEmpty) ...[
                              _buildAlertCard(
                                icon: Icons.event_busy_rounded,
                                color: Colors.red.shade400,
                                bgColor: Colors.red.shade400,
                                count: prodCtrl.expiredProducts.length,
                                label: 'Kedaluwarsa',
                                subtitle: 'Segera hapus',
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (prodCtrl.expiringSoonProducts.isNotEmpty)
                              _buildAlertCard(
                                icon: Icons.schedule_rounded,
                                color: Colors.orange,
                                bgColor: Colors.orange,
                                count: prodCtrl.expiringSoonProducts.length,
                                label: 'Akan Kadaluarsa',
                                subtitle: 'Dalam 7 hari',
                              ),
                            if (prodCtrl.expiredProducts.isEmpty &&
                                prodCtrl.expiringSoonProducts.isEmpty)
                              const Spacer(),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ─── Quick Insights ────────────────────────
                  FutureBuilder<AnalyticsData>(
                    future: AnalyticsService.getAnalytics(
                      from: DateTime.now().subtract(const Duration(days: 7)),
                      to: DateTime.now(),
                    ),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      final analytics = snap.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Business Insights'),
                          const SizedBox(height: 12),
                          _buildInsightCard(
                            icon: Icons.show_chart_rounded,
                            iconColor: AppTheme.primaryColor,
                            title: 'Rata-rata Transaksi',
                            value: formatCurrency(analytics.avgTransactionValue),
                            subtitle: '7 hari terakhir',
                          ),
                          const SizedBox(height: 10),
                          _buildInsightCard(
                            icon: Icons.access_time_filled,
                            iconColor: Colors.deepOrange,
                            title: 'Jam Tersibuk',
                            value: '${analytics.peakHour.toString().padLeft(2, '0')}:00',
                            subtitle: analytics.hourlySales.isNotEmpty
                                ? '${analytics.hourlySales.where((h) => h.hour == analytics.peakHour).first.txCount} transaksi'
                                : 'Data tidak tersedia',
                          ),
                          const SizedBox(height: 10),
                          if (analytics.products.isNotEmpty)
                            _buildInsightCard(
                              icon: Icons.star_rounded,
                              iconColor: AppTheme.warningColor,
                              title: 'Produk Terlaris',
                              value: analytics.products.first.productName,
                              subtitle: '${analytics.products.first.totalQty} terjual',
                            ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // ─── Recent Transactions ───────────────────
                  _sectionTitle('Transaksi Terbaru'),
                  const SizedBox(height: 12),

                  if (txCtrl.recentTransactions.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada transaksi',
                      subtitle: 'Mulai catat penjualan pertamamu!',
                    )
                  else
                    ...txCtrl.recentTransactions.take(5).map(
                          (tx) => TransactionListItem(
                            transaction: tx,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => TransactionDetailSheet(
                                  transaction: tx,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  /// Large metric card (full width)
  Widget _buildMetricCard({
    required Color backgroundColor,
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Compact metric card (half width)
  Widget _buildCompactMetricCard({
    required Color backgroundColor,
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    bool isProfit = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: Colors.white),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Quick tool shortcut card
  Widget _buildToolCard({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }

  /// Insight card for analytics
  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Modern alert card with badge and icon
  Widget _buildAlertCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required int count,
    required String label,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: bgColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: bgColor,
                    size: 22,
                  ),
                ),
                // Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
