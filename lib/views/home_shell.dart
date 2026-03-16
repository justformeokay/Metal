import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../utils/constants.dart';
import 'dashboard/dashboard_view.dart';
import 'products/product_list_view.dart';
import 'products/stock_alerts_view.dart';
import 'sales/sales_view.dart';
import 'sales/sales_history_view.dart';
import 'expenses/expense_list_view.dart';
import 'settings/settings_view.dart';
import 'printer/printer_settings_view.dart';
import 'profit_loss/profit_loss_view.dart';
import 'analytics/advanced_analytics_view.dart';
import 'reports/reports_view.dart';
import 'calculator/finance_calculator_view.dart';
import 'members/members_view.dart';

// ── Nav item metadata ────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItemData(this.icon, this.label, this.color);
}

const _navItems = [
  _NavItemData(Bootstrap.house_door_fill, 'Beranda',    Color(0xFFF59E0B)),
  _NavItemData(Bootstrap.cart3,           'Penjualan',  Color(0xFF10B981)),
  _NavItemData(Bootstrap.box_seam,        'Produk',     Color(0xFF3B82F6)),
  _NavItemData(Bootstrap.receipt_cutoff,  'Pengeluaran',Color(0xFFEF4444)),
  _NavItemData(Bootstrap.grid,            'Lainnya',    Color(0xFF8B5CF6)),
];

// ── HomeShell ────────────────────────────────────────────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardView(),
    SalesView(),
    ProductListView(),
    ExpenseListView(),
    _MoreMenuView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Floating navbar ──────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1117) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (i) => _NavItem(
                data: _navItems[i],
                isSelected: currentIndex == i,
                isDark: isDark,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? data.color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? data.color.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.icon,
              size: 20,
              color: isSelected
                  ? data.color
                  : (isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(
                        data.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: data.color,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── More menu ─────────────────────────────────────────────────────────────────

class _MoreMenuView extends StatelessWidget {
  const _MoreMenuView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? const Color(0xFF080B14) : const Color(0xFFF4F6FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: const Text(
          'Lainnya',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.5),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              _sectionLabel('Keuangan', isDark),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.graph_up,
                color: const Color(0xFF10B981),
                title: 'Laba & Rugi',
                subtitle: 'Lihat keuntungan bisnis kamu',
                page: const ProfitLossView(),
              ),
              const SizedBox(height: 10),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.clock_history,
                color: const Color(0xFFF97316),
                title: 'Riwayat Penjualan',
                subtitle: 'Detail transaksi per hari',
                page: const SalesHistoryView(),
              ),
              const SizedBox(height: 10),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.file_earmark_bar_graph,
                color: const Color(0xFF3B82F6),
                title: 'Laporan',
                subtitle: 'Laporan penjualan & pengeluaran',
                page: const ReportsView(),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Inventori & Analisis', isDark),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.bell,
                color: const Color(0xFFEF4444),
                title: 'Peringatan Stok',
                subtitle: 'Stok menipis, habis & kedaluwarsa',
                page: const StockAlertsView(),
              ),
              const SizedBox(height: 10),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.bar_chart_line,
                color: const Color(0xFF8B5CF6),
                title: 'Analisis Bisnis',
                subtitle: 'Tren, prediksi & insight otomatis',
                page: const AdvancedAnalyticsView(),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Pelanggan & Tools', isDark),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.people,
                color: const Color(0xFF06B6D4),
                title: 'Member',
                subtitle: 'Kelola member & diskon pelanggan',
                page: const MembersView(),
              ),
              const SizedBox(height: 10),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.calculator,
                color: const Color(0xFFF59E0B),
                title: 'Kalkulator Keuangan',
                subtitle: 'Kembalian, diskon, margin & pajak',
                page: const FinanceCalculatorView(),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Sistem', isDark),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.printer,
                color: const Color(0xFF64748B),
                title: 'Pengaturan Printer',
                subtitle: 'Kertas, margin, koneksi printer',
                page: const PrinterSettingsView(),
              ),
              const SizedBox(height: 10),
              _MoreCard(
                isDark: isDark,
                icon: Bootstrap.gear,
                color: const Color(0xFF6B7280),
                title: 'Pengaturan',
                subtitle: 'Profil bisnis, tema, backup',
                page: const SettingsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFF10B981)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color:
                  isDark ? Colors.white70 : const Color(0xFF1A1F2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── More card ─────────────────────────────────────────────────────────────────

class _MoreCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget page;

  const _MoreCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.06 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1F2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Bootstrap.chevron_right, color: color, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

