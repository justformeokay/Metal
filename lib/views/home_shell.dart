import 'package:flutter/material.dart';
import 'dashboard/dashboard_view.dart';
import 'products/product_list_view.dart';
import 'products/stock_alerts_view.dart';
import 'sales/sales_view.dart';
import 'sales/sales_history_view.dart';
import 'expenses/expense_list_view.dart';
import 'settings/settings_view.dart';
import 'profit_loss/profit_loss_view.dart';
import 'analytics/advanced_analytics_view.dart';
import 'reports/reports_view.dart';
import 'calculator/finance_calculator_view.dart';

/// Main shell with bottom navigation.
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_rounded),
            label: 'Penjualan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off_rounded),
            label: 'Pengeluaran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}

/// "More" menu that links to additional features.
class _MoreMenuView extends StatelessWidget {
  const _MoreMenuView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lainnya'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuTile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.green,
            title: 'Laba & Rugi',
            subtitle: 'Lihat keuntungan bisnis kamu',
            page: const ProfitLossView(),
          ),
          _menuTile(
            context,
            icon: Icons.receipt_long_rounded,
            color: Colors.orange,
            title: 'Riwayat Penjualan',
            subtitle: 'Detail transaksi per hari',
            page: const SalesHistoryView(),
          ),
          _menuTile(
            context,
            icon: Icons.notifications_active_rounded,
            color: Colors.red,
            title: 'Peringatan Stok',
            subtitle: 'Stok menipis, habis & kedaluwarsa',
            page: const StockAlertsView(),
          ),
          _menuTile(
            context,
            icon: Icons.auto_graph_rounded,
            color: Colors.deepPurple,
            title: 'Analisis Bisnis',
            subtitle: 'Tren, prediksi & insight otomatis',
            page: const AdvancedAnalyticsView(),
          ),
          _menuTile(
            context,
            icon: Icons.bar_chart_rounded,
            color: Colors.blue,
            title: 'Laporan',
            subtitle: 'Laporan penjualan & pengeluaran',
            page: const ReportsView(),
          ),
          _menuTile(
            context,
            icon: Icons.calculate_rounded,
            color: Colors.teal,
            title: 'Kalkulator Keuangan',
            subtitle: 'Kembalian, diskon, margin & pajak',
            page: const FinanceCalculatorView(),
          ),
          _menuTile(
            context,
            icon: Icons.settings_rounded,
            color: Colors.grey,
            title: 'Pengaturan',
            subtitle: 'Profil bisnis, tema, backup',
            page: const SettingsView(),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}
