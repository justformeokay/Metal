import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/expense_controller.dart';
import '../../models/expense.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import 'expense_form_view.dart';

// ── Category colour palette (deterministic) ───────────────────────────────
const _categoryColors = <String, Color>{
  'Bahan Baku':    Color(0xFF10B981),
  'Listrik & Air': Color(0xFFF59E0B),
  'Sewa':          Color(0xFF8B5CF6),
  'Kemasan':       Color(0xFF06B6D4),
  'Transportasi':  Color(0xFFF97316),
  'Gaji':          Color(0xFF3B82F6),
  'Peralatan':     Color(0xFFEC4899),
  'Lainnya':       Color(0xFF6B7280),
};

Color _colorFor(String category) =>
    _categoryColors[category] ?? const Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────────────────────────

/// Redesigned expense list view with financial summary & pie chart.
class ExpenseListView extends StatefulWidget {
  const ExpenseListView({super.key});

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  int _touchedIndex = -1;
  // Filter: 'week' | 'month' | 'all'
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseController>().loadExpenses();
    });
  }

  List<Expense> _filtered(List<Expense> all) {
    final now = DateTime.now();
    return all.where((e) {
      if (_period == 'week') {
        return e.date.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_period == 'month') {
        return e.date.year == now.year && e.date.month == now.month;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, double> _byCategory(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExpenseController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;
    final filtered = _filtered(ctrl.expenses);
    final total = filtered.fold<double>(0, (s, e) => s + e.amount);
    final byCategory = _byCategory(filtered);
    final topCategory = byCategory.isEmpty
        ? '-'
        : (byCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF080B14) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF080B14) : const Color(0xFFF4F6FA),
        elevation: 0,
        title: const Text(
          'Pengeluaran',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.dangerColor.withValues(alpha: 0.12),
              foregroundColor: AppTheme.dangerColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _openForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SizedBox(
                width: ResponsiveHelper.getButtonWidth(
                    context, tabletPercent: 0.5),
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<ExpenseController>().loadExpenses(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    children: [
                      // ── Period filter chips ───────────────
                      Row(
                        children: [
                          _PeriodChip(
                            label: 'Minggu ini',
                            value: 'week',
                            selected: _period == 'week',
                            onTap: () => setState(() => _period = 'week'),
                          ),
                          const SizedBox(width: 8),
                          _PeriodChip(
                            label: 'Bulan ini',
                            value: 'month',
                            selected: _period == 'month',
                            onTap: () => setState(() => _period = 'month'),
                          ),
                          const SizedBox(width: 8),
                          _PeriodChip(
                            label: 'Semua',
                            value: 'all',
                            selected: _period == 'all',
                            onTap: () => setState(() => _period = 'all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Hero total card ───────────────────
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.dangerColor
                                .withValues(alpha: isDark ? 0.3 : 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.dangerColor
                                  .withValues(alpha: isDark ? 0.10 : 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 7, height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.dangerColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        _periodLabel(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      formatCurrency(total),
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1F2E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${filtered.length} transaksi · terbesar: $topCategory',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.dangerColor
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.dangerColor
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: AppTheme.dangerColor, size: 26),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Stats row ─────────────────────────
                      if (filtered.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                isDark: isDark,
                                label: 'Terbesar',
                                value: formatCurrency(filtered
                                    .map((e) => e.amount)
                                    .reduce((a, b) => a > b ? a : b)),
                                icon: Icons.arrow_upward_rounded,
                                color: AppTheme.dangerColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                isDark: isDark,
                                label: 'Rata-rata',
                                value: formatCurrency(total / filtered.length),
                                icon: Icons.bar_chart_rounded,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                isDark: isDark,
                                label: 'Kategori',
                                value: '${byCategory.length}',
                                icon: Icons.category_outlined,
                                color: const Color(0xFF8B5CF6),
                                isCount: true,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // ── Pie chart card ────────────────────
                      if (byCategory.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.0 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4, height: 18,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.dangerColor,
                                          Color(0xFFF97316),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Komposisi Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1F2E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 200,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: PieChart(
                                        PieChartData(
                                          pieTouchData: PieTouchData(
                                            touchCallback: (event, response) {
                                              setState(() {
                                                _touchedIndex = response
                                                            ?.touchedSection
                                                            ?.touchedSectionIndex ??
                                                        -1;
                                              });
                                            },
                                          ),
                                          borderData: FlBorderData(show: false),
                                          sectionsSpace: 3,
                                          centerSpaceRadius: 48,
                                          sections: _buildSections(
                                              byCategory, total),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 4,
                                      child: _buildLegend(
                                          byCategory, total, isDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Section header ────────────────────
                      Row(
                        children: [
                          Container(
                            width: 4, height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.dangerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Riwayat Transaksi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1F2E),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${filtered.length} data',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Expense list ──────────────────────
                      if (filtered.isEmpty)
                        EmptyState(
                          icon: Icons.money_off_rounded,
                          title: 'Belum ada pengeluaran',
                          subtitle: 'Catat pengeluaran bisnis kamu',
                          action: ElevatedButton.icon(
                            onPressed: () => _openForm(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Pengeluaran'),
                          ),
                        )
                      else
                        ...filtered.map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ExpenseCard(
                              expense: expense,
                              isDark: isDark,
                              onTap: () =>
                                  _openForm(context, expense: expense),
                              onDelete: () => _confirmDelete(
                                  context, expense.id, expense.name),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<PieChartSectionData> _buildSections(
      Map<String, double> byCategory, double total) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final pct = total > 0 ? entries[i].value / total * 100 : 0;
      return PieChartSectionData(
        color: _colorFor(entries[i].key),
        value: entries[i].value,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 56 : 48,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend(
      Map<String, double> byCategory, double total, bool isDark) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.take(6).map((e) {
        final pct = total > 0 ? e.value / total * 100 : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _colorFor(e.key),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _colorFor(e.key),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _periodLabel() {
    if (_period == 'week') return 'Pengeluaran Minggu Ini';
    if (_period == 'month') return 'Pengeluaran Bulan Ini';
    return 'Total Semua Pengeluaran';
  }

  void _openForm(BuildContext context, {Expense? expense}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormView(expense: expense)),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pengeluaran',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseController>().deleteExpense(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus',
                style: TextStyle(
                    color: AppTheme.dangerColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Period chip ────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.dangerColor
              : (isDark
                  ? const Color(0xFF1A1F2E)
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.dangerColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.dangerColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

// ── Stat mini card ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isCount;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.06 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isCount ? 22 : 13,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expense list card ──────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.isDark,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(expense.category);
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.07 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4, height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.receipt_outlined, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatDate(expense.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount + delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(expense.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 15, color: AppTheme.dangerColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


