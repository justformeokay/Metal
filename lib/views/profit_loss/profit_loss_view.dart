import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/expense_controller.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/summary_card.dart';

/// Profit & Loss overview with daily/weekly/monthly tabs.
class ProfitLossView extends StatefulWidget {
  const ProfitLossView({super.key});

  @override
  State<ProfitLossView> createState() => _ProfitLossViewState();
}

class _ProfitLossViewState extends State<ProfitLossView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  double _sales = 0;
  double _cogs = 0;
  double _expenses = 0;
  bool _isLoading = true;

  // Chart data — last 7 days profit
  List<double> _dailyProfits = [];
  List<String> _dailyLabels = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  DateTimeRange _getRange() {
    switch (_tabCtrl.index) {
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

    final sales = await txCtrl.getSalesTotal(
        from: range.start, to: range.end);
    final cogs = await txCtrl.getCostTotal(
        from: range.start, to: range.end);
    final expenses = await expCtrl.getExpenseTotal(
        from: range.start, to: range.end);

    // Build 7-day chart data
    final now = DateTime.now();
    List<double> profits = [];
    List<String> labels = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final s = await txCtrl.getSalesTotal(from: dayStart, to: dayEnd);
      final c = await txCtrl.getCostTotal(from: dayStart, to: dayEnd);
      final e = await expCtrl.getExpenseTotal(from: dayStart, to: dayEnd);
      profits.add(s - c - e);
      labels.add(formatDateShort(day));
    }

    if (mounted) {
      setState(() {
        _sales = sales;
        _cogs = cogs;
        _expenses = expenses;
        _dailyProfits = profits;
        _dailyLabels = labels;
        _isLoading = false;
      });
    }
  }

  double get _profit => _sales - _cogs - _expenses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laba & Rugi'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Hari Ini'),
            Tab(text: 'Minggu Ini'),
            Tab(text: 'Bulan Ini'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── Summary Cards ─────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: [
                      SummaryCard(
                        title: 'Penjualan',
                        value: formatCurrency(_sales),
                        icon: Icons.trending_up_rounded,
                        iconColor: AppTheme.accentColor,
                      ),
                      SummaryCard(
                        title: 'HPP',
                        value: formatCurrency(_cogs),
                        icon: Icons.inventory_rounded,
                        iconColor: AppTheme.warningColor,
                      ),
                      SummaryCard(
                        title: 'Pengeluaran',
                        value: formatCurrency(_expenses),
                        icon: Icons.money_off_rounded,
                        iconColor: AppTheme.dangerColor,
                      ),
                      SummaryCard(
                        title: 'Keuntungan',
                        value: formatCurrency(_profit),
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: _profit >= 0
                            ? AppTheme.accentColor
                            : AppTheme.dangerColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ─── Profit Formula ────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).dividerTheme.color ??
                            AppTheme.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rumus Laba',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _formulaRow('Penjualan', _sales, AppTheme.accentColor),
                        _formulaRow('- HPP (Modal)', _cogs, AppTheme.warningColor),
                        _formulaRow(
                            '- Pengeluaran', _expenses, AppTheme.dangerColor),
                        const Divider(height: 16),
                        _formulaRow(
                          '= Keuntungan',
                          _profit,
                          _profit >= 0
                              ? AppTheme.accentColor
                              : AppTheme.dangerColor,
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── 7-day Profit Chart ────────────────
                  const Text('Grafik Laba 7 Hari Terakhir',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: _buildChart(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _formulaRow(String label, double value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: bold ? 15 : 14,
              )),
          Text(
            formatCurrency(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_dailyProfits.isEmpty) {
      return const Center(child: Text('Belum ada data'));
    }

    final maxY = _dailyProfits.isEmpty
        ? 100.0
        : (_dailyProfits.reduce((a, b) => a > b ? a : b)).abs() * 1.3;
    final minY = _dailyProfits.isEmpty
        ? -100.0
        : (_dailyProfits.reduce((a, b) => a < b ? a : b));
    final effectiveMinY = minY < 0 ? minY * 1.3 : 0.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 100 : maxY,
        minY: effectiveMinY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gIndex, rod, rIndex) {
              return BarTooltipItem(
                formatCurrencyShort(rod.toY),
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < _dailyLabels.length) {
                  return Text(_dailyLabels[idx],
                      style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_dailyProfits.length, (i) {
          final val = _dailyProfits[i];
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: val,
              color: val >= 0 ? AppTheme.accentColor : AppTheme.dangerColor,
              width: 24,
              borderRadius: BorderRadius.circular(6),
            ),
          ]);
        }),
      ),
    );
  }
}
