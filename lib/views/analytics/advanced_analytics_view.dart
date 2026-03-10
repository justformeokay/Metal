import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/analytics_service.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';

/// Advanced Analytics & Business Insights page.
class AdvancedAnalyticsView extends StatefulWidget {
  const AdvancedAnalyticsView({super.key});

  @override
  State<AdvancedAnalyticsView> createState() => _AdvancedAnalyticsViewState();
}

class _AdvancedAnalyticsViewState extends State<AdvancedAnalyticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = true;

  // Period state
  int _selectedPeriod = 1; // 0=7d, 1=30d, 2=90d
  static const _periodLabels = ['7 Hari', '30 Hari', '90 Hari'];
  static const _periodDays = [7, 30, 90];

  // Data
  AnalyticsData? _analytics;
  PeriodComparison? _comparison;
  List<DailySalesData> _predictions = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final days = _periodDays[_selectedPeriod];
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
    final to = now;
    final prevFrom = from.subtract(Duration(days: days));
    final prevTo = from;

    final results = await Future.wait([
      AnalyticsService.getAnalytics(from: from, to: to),
      AnalyticsService.comparePeriods(
        currentFrom: from,
        currentTo: to,
        previousFrom: prevFrom,
        previousTo: prevTo,
      ),
    ]);

    final analytics = results[0] as AnalyticsData;
    final comparison = results[1] as PeriodComparison;
    final predictions = AnalyticsService.predictSales(
      analytics.dailySales,
      7,
    );

    if (mounted) {
      setState(() {
        _analytics = analytics;
        _comparison = comparison;
        _predictions = predictions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Bisnis'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Tren & Prediksi'),
            Tab(text: 'Produk'),
            Tab(text: 'Perbandingan'),
            Tab(text: 'Insight'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: List.generate(3, (i) {
                final selected = _selectedPeriod == i;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 4, right: i == 2 ? 0 : 4),
                    child: ChoiceChip(
                      label: Text(_periodLabels[i]),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedPeriod = i);
                        _loadData();
                      },
                      selectedColor:
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildTrendTab(),
                      _buildProductsTab(),
                      _buildComparisonTab(),
                      _buildInsightsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: Tren & Prediksi
  // ═══════════════════════════════════════════════════════════

  Widget _buildTrendTab() {
    final data = _analytics!;
    if (data.dailySales.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart_rounded,
        title: 'Belum ada data',
        subtitle: 'Mulai catat penjualan untuk melihat tren.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sales trend chart
        _SectionHeader(title: 'Tren Penjualan', icon: Icons.trending_up),
        const SizedBox(height: 8),
        _buildSalesTrendChart(data.dailySales, _predictions),
        const SizedBox(height: 24),

        // Profit trend chart
        _SectionHeader(title: 'Tren Keuntungan', icon: Icons.show_chart),
        const SizedBox(height: 8),
        _buildProfitTrendChart(data.dailySales),
        const SizedBox(height: 24),

        // Prediction summary
        if (_predictions.isNotEmpty) ...[
          _SectionHeader(
              title: 'Prediksi 7 Hari', icon: Icons.auto_graph_rounded),
          const SizedBox(height: 8),
          _buildPredictionSummary(),
        ],
      ],
    );
  }

  Widget _buildSalesTrendChart(
      List<DailySalesData> actual, List<DailySalesData> predicted) {
    final allData = [...actual, ...predicted];
    if (allData.isEmpty) return const SizedBox.shrink();

    final maxY = allData.map((d) => d.sales).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.border.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (val, _) => Text(
                  formatCurrencyShort(val),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (allData.length / 5).ceilToDouble().clamp(1, 30),
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= allData.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('dd/MM').format(allData[i].date),
                      style: const TextStyle(
                          fontSize: 9, color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Actual sales line
            LineChartBarData(
              spots: List.generate(
                actual.length,
                (i) => FlSpot(i.toDouble(), actual[i].sales),
              ),
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppTheme.primaryColor,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            // Prediction dashed line
            if (predicted.isNotEmpty)
              LineChartBarData(
                spots: [
                  FlSpot(
                      (actual.length - 1).toDouble(), actual.last.sales),
                  ...List.generate(
                    predicted.length,
                    (i) => FlSpot(
                      (actual.length + i).toDouble(),
                      predicted[i].sales,
                    ),
                  ),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                barWidth: 2,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.spotIndex;
                final isPredict =
                    s.barIndex == 1 || (s.barIndex == 0 && i >= actual.length);
                return LineTooltipItem(
                  '${isPredict ? "Prediksi: " : ""}${formatCurrency(s.y)}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitTrendChart(List<DailySalesData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final profits = data.map((d) => d.profit).toList();
    final maxY =
        profits.map((p) => p.abs()).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: BarChart(
        BarChartData(
          minY: profits.any((p) => p < 0) ? -maxY * 1.1 : 0,
          maxY: maxY * 1.1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 3 : 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.border.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (val, _) => Text(
                  formatCurrencyShort(val),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (data.length / 5).ceilToDouble().clamp(1, 30),
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('dd/MM').format(data[i].date),
                      style: const TextStyle(
                          fontSize: 9, color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            final profit = data[i].profit;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: profit,
                width: (200 / data.length).clamp(2, 12),
                color: profit >= 0 ? AppTheme.accentColor : AppTheme.dangerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ]);
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gIdx, rod, rIdx) {
                final i = group.x;
                if (i < 0 || i >= data.length) return null;
                return BarTooltipItem(
                  '${formatDateShort(data[i].date)}\n${formatCurrency(rod.toY)}',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionSummary() {
    final totalPredicted =
        _predictions.fold(0.0, (sum, d) => sum + d.sales);
    final avgPredicted =
        _predictions.isNotEmpty ? totalPredicted / _predictions.length : 0.0;
    final trend = _predictions.length >= 2
        ? _predictions.last.sales - _predictions.first.sales
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Estimasi 7 Hari Ke Depan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _predictionMetric(
                  'Total Prediksi', formatCurrencyShort(totalPredicted)),
              _predictionMetric(
                  'Rata-rata/Hari', formatCurrencyShort(avgPredicted)),
              _predictionMetric(
                'Tren',
                trend >= 0 ? '↑ Naik' : '↓ Turun',
                color:
                    trend >= 0 ? AppTheme.accentColor : AppTheme.dangerColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _predictionMetric(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppTheme.primaryColor)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: Produk Ranking & Margin
  // ═══════════════════════════════════════════════════════════

  Widget _buildProductsTab() {
    final data = _analytics!;
    if (data.products.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Belum ada data penjualan',
        subtitle: 'Lakukan penjualan untuk melihat ranking produk.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top products chart
        _SectionHeader(
            title: 'Top Produk (Revenue)', icon: Icons.emoji_events_rounded),
        const SizedBox(height: 8),
        _buildTopProductsChart(data.products),
        const SizedBox(height: 24),

        // Product margin table
        _SectionHeader(
            title: 'Margin per Produk', icon: Icons.percent_rounded),
        const SizedBox(height: 8),
        _buildMarginTable(data.products),
        const SizedBox(height: 24),

        // Category breakdown
        if (data.categorySales.isNotEmpty) ...[
          _SectionHeader(
              title: 'Penjualan per Kategori',
              icon: Icons.category_rounded),
          const SizedBox(height: 8),
          _buildCategoryChart(data.categorySales),
        ],
      ],
    );
  }

  Widget _buildTopProductsChart(List<ProductAnalyticsData> products) {
    final top = products.take(8).toList();
    final maxRevenue =
        top.map((p) => p.totalRevenue).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: top.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          final percent =
              maxRevenue > 0 ? p.totalRevenue / maxRevenue : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i < 3
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    p.productName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percent,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 75,
                  child: Text(
                    formatCurrencyShort(p.totalRevenue),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMarginTable(List<ProductAnalyticsData> products) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Produk',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700))),
                Expanded(
                    flex: 2,
                    child: Text('Revenue',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700))),
                Expanded(
                    child: Text('Profit',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700))),
                SizedBox(width: 60, child: Text('Margin',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          // Rows
          ...products.take(15).map((p) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        p.productName,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatCurrencyShort(p.totalRevenue),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatCurrencyShort(p.totalProfit),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: p.totalProfit >= 0
                              ? AppTheme.accentColor
                              : AppTheme.dangerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _marginColor(p.marginPercent)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${p.marginPercent.toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _marginColor(p.marginPercent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _marginColor(double margin) {
    if (margin >= 30) return AppTheme.accentColor;
    if (margin >= 15) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }

  Widget _buildCategoryChart(List<CategorySalesData> categories) {
    final total =
        categories.fold(0.0, (sum, c) => sum + c.totalRevenue);
    const colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.orange,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: categories.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  final pct = total > 0 ? (c.totalRevenue / total * 100) : 0;
                  return PieChartSectionData(
                    value: c.totalRevenue,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    color: colors[i % colors.length],
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: categories.asMap().entries.map((e) {
              final i = e.key;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(e.value.category,
                      style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: Perbandingan Bulan
  // ═══════════════════════════════════════════════════════════

  Widget _buildComparisonTab() {
    final comp = _comparison!;
    if (comp.currentSales == 0 && comp.previousSales == 0) {
      return const EmptyState(
        icon: Icons.compare_arrows_rounded,
        title: 'Data belum cukup',
        subtitle:
            'Butuh minimal 2 periode data untuk perbandingan.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
            title: 'Perbandingan Periode', icon: Icons.compare_arrows),
        const SizedBox(height: 4),
        Text(
          'vs ${_periodLabels[_selectedPeriod]} sebelumnya',
          style:
              const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // Growth cards
        Row(
          children: [
            Expanded(
              child: _GrowthCard(
                title: 'Penjualan',
                current: comp.currentSales,
                previous: comp.previousSales,
                growth: comp.salesGrowth,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GrowthCard(
                title: 'Keuntungan',
                current: comp.currentProfit,
                previous: comp.previousProfit,
                growth: comp.profitGrowth,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GrowthCard(
                title: 'Pengeluaran',
                current: comp.currentExpenses,
                previous: comp.previousExpenses,
                growth: comp.expenseGrowth,
                icon: Icons.money_off_rounded,
                invertColor: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GrowthCard(
                title: 'Jumlah Transaksi',
                current: comp.currentTxCount.toDouble(),
                previous: comp.previousTxCount.toDouble(),
                growth: comp.txCountGrowth,
                icon: Icons.receipt_rounded,
                isCurrency: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Average transaction comparison
        _SectionHeader(
            title: 'Rata-rata Transaksi', icon: Icons.analytics_rounded),
        const SizedBox(height: 8),
        _ComparisonBar(
          label: 'Sekarang',
          value: comp.currentAvgTx,
          maxValue: [comp.currentAvgTx, comp.previousAvgTx]
              .reduce((a, b) => a > b ? a : b),
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
        _ComparisonBar(
          label: 'Sebelumnya',
          value: comp.previousAvgTx,
          maxValue: [comp.currentAvgTx, comp.previousAvgTx]
              .reduce((a, b) => a > b ? a : b),
          color: AppTheme.textSecondary,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 4: Insights / Ringkasan
  // ═══════════════════════════════════════════════════════════

  Widget _buildInsightsTab() {
    final data = _analytics!;
    final comp = _comparison!;
    if (data.dailySales.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Belum ada insight',
        subtitle: 'Mulai catat penjualan untuk mendapat insight bisnis.',
      );
    }

    final insights = _generateInsights(data, comp);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Key metrics summary
        _SectionHeader(title: 'Ringkasan Kunci', icon: Icons.key_rounded),
        const SizedBox(height: 8),
        _buildKeyMetrics(data),
        const SizedBox(height: 24),

        // Peak hours
        if (data.hourlySales.isNotEmpty) ...[
          _SectionHeader(
              title: 'Jam Ramai', icon: Icons.access_time_rounded),
          const SizedBox(height: 8),
          _buildPeakHoursChart(data.hourlySales),
          const SizedBox(height: 24),
        ],

        // AI Insights
        _SectionHeader(
            title: 'Insight Otomatis', icon: Icons.lightbulb_rounded),
        const SizedBox(height: 8),
        ...insights.map((insight) => _InsightCard(insight: insight)),
      ],
    );
  }

  Widget _buildKeyMetrics(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _metricItem('Total Penjualan',
                  formatCurrencyShort(data.totalSales)),
              _metricItem(
                  'Total Keuntungan', formatCurrencyShort(data.totalProfit)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _metricItem('Transaksi', '${data.txCount}'),
              _metricItem(
                  'Rata-rata', formatCurrencyShort(data.avgTransactionValue)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _metricItem('Produk Terjual', '${data.products.length} jenis'),
              _metricItem(
                  'Jam Ramai', '${data.peakHour.toString().padLeft(2, '0')}:00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart(List<HourlySalesData> hourly) {
    final maxTx =
        hourly.map((h) => h.txCount).reduce((a, b) => a > b ? a : b);

    // Fill all 24 hours
    final allHours = List.generate(24, (h) {
      final match = hourly.where((d) => d.hour == h);
      return match.isNotEmpty ? match.first : HourlySalesData(hour: h, sales: 0, txCount: 0);
    });

    return Container(
      height: 160,
      padding: const EdgeInsets.only(right: 8, top: 12, left: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxTx.toDouble() * 1.3,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 3,
                getTitlesWidget: (val, _) {
                  final h = val.toInt();
                  if (h % 3 != 0) return const SizedBox();
                  return Text(h.toString().padLeft(2, '0'),
                      style: const TextStyle(
                          fontSize: 9, color: AppTheme.textSecondary));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: allHours.map((h) {
            final intensity = maxTx > 0 ? h.txCount / maxTx : 0.0;
            return BarChartGroupData(x: h.hour, barRods: [
              BarChartRodData(
                toY: h.txCount.toDouble(),
                width: 8,
                color: Color.lerp(
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor,
                  intensity,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3)),
              ),
            ]);
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gIdx, rod, rIdx) {
                final h = group.x;
                final hourData = allHours[h];
                return BarTooltipItem(
                  '${h.toString().padLeft(2, '0')}:00\n${hourData.txCount} transaksi\n${formatCurrencyShort(hourData.sales)}',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<InsightData> _generateInsights(
      AnalyticsData data, PeriodComparison comp) {
    final insights = <InsightData>[];

    // Sales growth insight
    if (comp.previousSales > 0) {
      final growth = comp.salesGrowth;
      insights.add(InsightData(
        icon: growth >= 0 ? Icons.trending_up : Icons.trending_down,
        color: growth >= 0 ? AppTheme.accentColor : AppTheme.dangerColor,
        title: growth >= 0 ? 'Penjualan Naik!' : 'Penjualan Turun',
        description:
            'Penjualan ${growth >= 0 ? "naik" : "turun"} ${growth.abs().toStringAsFixed(1)}% dibanding periode sebelumnya.',
      ));
    }

    // Top product insight
    if (data.products.isNotEmpty) {
      final top = data.products.first;
      insights.add(InsightData(
        icon: Icons.star_rounded,
        color: AppTheme.warningColor,
        title: 'Produk Terlaris: ${top.productName}',
        description:
            'Terjual ${top.totalQty} unit dengan revenue ${formatCurrencyShort(top.totalRevenue)} dan margin ${top.marginPercent.toStringAsFixed(0)}%.',
      ));
    }

    // Margin warning
    final lowMarginProducts =
        data.products.where((p) => p.marginPercent < 15 && p.totalRevenue > 0);
    if (lowMarginProducts.isNotEmpty) {
      insights.add(InsightData(
        icon: Icons.warning_amber_rounded,
        color: AppTheme.dangerColor,
        title: '${lowMarginProducts.length} Produk Margin Rendah',
        description:
            'Produk dengan margin <15%: ${lowMarginProducts.take(3).map((p) => p.productName).join(", ")}. Pertimbangkan naikkan harga.',
      ));
    }

    // High margin products
    final highMarginProducts =
        data.products.where((p) => p.marginPercent >= 40 && p.totalRevenue > 0);
    if (highMarginProducts.isNotEmpty) {
      insights.add(InsightData(
        icon: Icons.thumb_up_rounded,
        color: AppTheme.accentColor,
        title: '${highMarginProducts.length} Produk Margin Tinggi',
        description:
            'Fokus promosi: ${highMarginProducts.take(3).map((p) => "${p.productName} (${p.marginPercent.toStringAsFixed(0)}%)").join(", ")}.',
      ));
    }

    // Peak hour insight
    if (data.hourlySales.isNotEmpty) {
      final peak =
          data.hourlySales.reduce((a, b) => a.txCount > b.txCount ? a : b);
      insights.add(InsightData(
        icon: Icons.access_time_filled,
        color: AppTheme.infoColor,
        title: 'Jam Tersibuk: ${peak.hour.toString().padLeft(2, '0')}:00',
        description:
            '${peak.txCount} transaksi dengan total ${formatCurrencyShort(peak.sales)}. Pastikan staf cukup di jam ini.',
      ));
    }

    // Average transaction value
    if (data.avgTransactionValue > 0) {
      insights.add(InsightData(
        icon: Icons.payments_rounded,
        color: AppTheme.primaryColor,
        title:
            'Rata-rata Transaksi: ${formatCurrencyShort(data.avgTransactionValue)}',
        description:
            'Transaksi terbesar: ${formatCurrency(data.maxTransactionValue)}. Pertimbangkan bundling untuk naikkan nilai transaksi.',
      ));
    }

    return insights;
  }
}

// ─── Reusable Widgets ──────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GrowthCard extends StatelessWidget {
  final String title;
  final double current;
  final double previous;
  final double growth;
  final IconData icon;
  final bool invertColor;
  final bool isCurrency;

  const _GrowthCard({
    required this.title,
    required this.current,
    required this.previous,
    required this.growth,
    required this.icon,
    this.invertColor = false,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = invertColor ? growth <= 0 : growth >= 0;
    final growthColor =
        isPositive ? AppTheme.accentColor : AppTheme.dangerColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCurrency
                ? formatCurrencyShort(current)
                : current.toInt().toString(),
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                growth >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: growthColor,
              ),
              const SizedBox(width: 2),
              Text(
                '${growth.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: growthColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    formatCurrencyShort(value),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final InsightData insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight.icon, color: insight.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  insight.description,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsightData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  InsightData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
