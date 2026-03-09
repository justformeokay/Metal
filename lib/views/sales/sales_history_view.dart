import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

/// Sales history page — view all transactions grouped by date with filters.
class SalesHistoryView extends StatefulWidget {
  const SalesHistoryView({super.key});

  @override
  State<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<SalesHistoryView> {
  final DatabaseService _db = DatabaseService();

  List<SalesTransaction> _transactions = [];
  bool _isLoading = true;

  // Filter state
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _filterLabel = '30 Hari Terakhir';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final transactions = await _db.getTransactions(from: start, to: end);
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    }
  }

  /// Group transactions by date (yyyy-MM-dd).
  Map<String, List<SalesTransaction>> _groupByDate() {
    final grouped = <String, List<SalesTransaction>>{};
    for (final tx in _transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = _groupByDate();
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penjualan'),
      ),
      body: Column(
        children: [
          // ─── Filter Bar ──────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade800 : AppTheme.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('Hari Ini', () => _setQuickFilter('Hari Ini')),
                        const SizedBox(width: 8),
                        _filterChip('7 Hari', () => _setQuickFilter('7 Hari')),
                        const SizedBox(width: 8),
                        _filterChip('30 Hari', () => _setQuickFilter('30 Hari')),
                        const SizedBox(width: 8),
                        _filterChip('Bulan Ini', () => _setQuickFilter('Bulan Ini')),
                        const SizedBox(width: 8),
                        _filterChip('Semua', () => _setQuickFilter('Semua')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                  tooltip: 'Pilih rentang tanggal',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),

          // ─── Summary Bar ─────────────────────────
          if (!_isLoading && _transactions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primaryColor.withAlpha(isDark ? 30 : 15),
              child: Row(
                children: [
                  _summaryItem(
                    'Transaksi',
                    '${_transactions.length}',
                  ),
                  _summaryItem(
                    'Total Penjualan',
                    formatCurrency(
                      _transactions.fold(0.0, (sum, tx) => sum + tx.totalAmount),
                    ),
                  ),
                  _summaryItem(
                    'Laba Kotor',
                    formatCurrency(
                      _transactions.fold(0.0, (sum, tx) => sum + tx.profit),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Filter Info ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _filterLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_transactions.length} transaksi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ─── Transaction List ────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            final dateKey = sortedDates[index];
                            final dayTxs = grouped[dateKey]!;
                            return _buildDateGroup(dateKey, dayTxs, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─── Date Group ──────────────────────────────────

  Widget _buildDateGroup(
      String dateKey, List<SalesTransaction> txs, bool isDark) {
    final date = DateTime.parse(dateKey);
    final dayLabel = _formatDayLabel(date);
    final dayTotal = txs.fold(0.0, (sum, tx) => sum + tx.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${txs.length} transaksi',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                formatCurrency(dayTotal),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.primaryLight
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Transaction cards
        ...txs.map((tx) => _buildTransactionCard(tx, isDark)),
      ],
    );
  }

  // ─── Transaction Card ────────────────────────────

  Widget _buildTransactionCard(SalesTransaction tx, bool isDark) {
    final timeStr = DateFormat('HH:mm').format(tx.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetail(tx),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: time + total
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${tx.items.length} item',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency(tx.totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Item preview (first 3 items)
              ...tx.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantity}x',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            formatCurrency(item.subtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),

              if (tx.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '...dan ${tx.items.length - 3} item lainnya',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),

              // Profit info
              const Divider(height: 16),
              Row(
                children: [
                  Text(
                    'Laba: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    formatCurrency(tx.profit),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Transaction Detail Bottom Sheet ─────────────

  void _showTransactionDetail(SalesTransaction tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(tx.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Detail Transaksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Catatan: ${tx.notes}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Items table
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : AppTheme.border,
                  ),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text('Produk',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                )),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text('Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                )),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text('Harga',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                )),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text('Subtotal',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                )),
                          ),
                        ],
                      ),
                    ),

                    // Items
                    ...tx.items.map((item) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : AppTheme.border,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  formatCurrency(item.unitPrice),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  formatCurrency(item.subtotal),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Totals
              _detailRow('Total Penjualan', formatCurrency(tx.totalAmount),
                  bold: true),
              const SizedBox(height: 4),
              _detailRow('Total Modal', formatCurrency(tx.totalCost)),
              const SizedBox(height: 4),
              _detailRow(
                'Laba Kotor',
                formatCurrency(tx.profit),
                color: AppTheme.accentColor,
                bold: true,
              ),

              const SizedBox(height: 16),

              // Transaction ID
              Text(
                'ID: ${tx.id}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────

  Widget _detailRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            )),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: color,
            )),
      ],
    );
  }

  Widget _summaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onTap) {
    final isActive = _filterLabel.contains(label) ||
        (label == '30 Hari' && _filterLabel == '30 Hari Terakhir') ||
        (label == '7 Hari' && _filterLabel == '7 Hari Terakhir');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor
              : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? Colors.white
                : isDark
                    ? Colors.grey.shade300
                    : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Transaksi yang sudah selesai\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hari Ini';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
  }

  // ─── Filter Actions ──────────────────────────────

  void _setQuickFilter(String label) {
    final now = DateTime.now();

    switch (label) {
      case 'Hari Ini':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        _filterLabel = 'Hari Ini';
        break;
      case '7 Hari':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        _filterLabel = '7 Hari Terakhir';
        break;
      case '30 Hari':
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        _filterLabel = '30 Hari Terakhir';
        break;
      case 'Bulan Ini':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        _filterLabel = 'Bulan Ini';
        break;
      case 'Semua':
        _startDate = DateTime(2020, 1, 1);
        _endDate = now;
        _filterLabel = 'Semua';
        break;
    }

    _loadTransactions();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      _startDate = picked.start;
      _endDate = picked.end;
      _filterLabel =
          '${DateFormat('d MMM', 'id_ID').format(picked.start)} - ${DateFormat('d MMM yyyy', 'id_ID').format(picked.end)}';
      _loadTransactions();
    }
  }
}
