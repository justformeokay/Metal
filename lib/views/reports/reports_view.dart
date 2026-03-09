import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/expense_controller.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../services/pdf_service.dart';

/// Business reports — sales, expenses, top products.
class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  int _selectedPeriod = 0; // 0=today, 1=week, 2=month
  bool _isLoading = true;

  double _totalSales = 0;
  double _totalCost = 0;
  double _totalExpenses = 0;
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _expenseBreakdown = [];

  final _periodLabels = ['Hari Ini', 'Minggu Ini', 'Bulan Ini'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTimeRange _getRange() {
    switch (_selectedPeriod) {
      case 0:
        return DateRangeHelper.today();
      case 1:
        return DateRangeHelper.thisWeek();
      case 2:
        return DateRangeHelper.thisMonth();
      default:
        return DateRangeHelper.today();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final txCtrl = context.read<TransactionController>();
    final expCtrl = context.read<ExpenseController>();
    final range = _getRange();

    final sales =
        await txCtrl.getSalesTotal(from: range.start, to: range.end);
    final cost =
        await txCtrl.getCostTotal(from: range.start, to: range.end);
    final expenses =
        await expCtrl.getExpenseTotal(from: range.start, to: range.end);
    final top = await txCtrl.getTopSellingProducts(
        from: range.start, to: range.end);
    final breakdown =
        await expCtrl.getExpenseBreakdown(from: range.start, to: range.end);

    if (mounted) {
      setState(() {
        _totalSales = sales;
        _totalCost = cost;
        _totalExpenses = expenses;
        _topProducts = top;
        _expenseBreakdown = breakdown;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Period selector
                  Row(
                    children: List.generate(3, (i) {
                      final selected = _selectedPeriod == i;
                      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: i > 0 ? 8 : 0),
                          child: ChoiceChip(
                            label: Text(_periodLabels[i]),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedPeriod = i);
                              _loadData();
                            },
                            backgroundColor: isDarkMode ? AppTheme.cardDark : Colors.white,
                            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : (isDarkMode 
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : AppTheme.textSecondary.withValues(alpha: 0.4)),
                              width: selected ? 2 : 1,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: selected 
                                  ? AppTheme.primaryColor
                                  : (isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary),
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ─── Sales Summary ─────────────────────
                  _buildSummaryTable(),
                  const SizedBox(height: 24),

                  // ─── Top Products ──────────────────────
                  const Text('Produk Terlaris',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_topProducts.isEmpty)
                    const Text('Belum ada data penjualan',
                        style: TextStyle(color: Colors.grey))
                  else
                    ..._topProducts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor)),
                        ),
                        title: Text(p['productName'] as String),
                        trailing: Text(
                          '${(p['totalQty'] as num).toInt()} terjual',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // ─── Expense Breakdown ─────────────────
                  const Text('Rincian Pengeluaran',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_expenseBreakdown.isEmpty)
                    const Text('Belum ada data pengeluaran',
                        style: TextStyle(color: Colors.grey))
                  else ...[
                    SizedBox(
                      height: 200,
                      child: _buildExpensePieChart(),
                    ),
                    const SizedBox(height: 16),
                    ..._expenseBreakdown.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e['category'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(
                              formatCurrency(
                                  (e['total'] as num).toDouble()),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryTable() {
    final profit = _totalSales - _totalCost - _totalExpenses;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          _row('Total Penjualan', formatCurrency(_totalSales),
              AppTheme.accentColor),
          _row('HPP (Modal)', formatCurrency(_totalCost),
              AppTheme.warningColor),
          _row('Total Pengeluaran', formatCurrency(_totalExpenses),
              AppTheme.dangerColor),
          const Divider(height: 16),
          _row(
            'Laba Bersih',
            formatCurrency(profit),
            profit >= 0 ? AppTheme.accentColor : AppTheme.dangerColor,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _buildExpensePieChart() {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      AppTheme.dangerColor,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _expenseBreakdown.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final total = (e['total'] as num).toDouble();
          return PieChartSectionData(
            value: total,
            title: formatCurrencyShort(total),
            color: colors[i % colors.length],
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _exportPdf() async {
    try {
      final range = _getRange();
      await PdfService.generateReport(
        periodLabel: _periodLabels[_selectedPeriod],
        totalSales: _totalSales,
        totalCost: _totalCost,
        totalExpenses: _totalExpenses,
        topProducts: _topProducts,
        expenseBreakdown: _expenseBreakdown,
        dateRange: range,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan PDF berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e')),
        );
      }
    }
  }
}
