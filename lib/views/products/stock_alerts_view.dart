import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import 'product_form_view.dart';

/// Stock Alerts & Inventory Management view.
class StockAlertsView extends StatelessWidget {
  const StockAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProductController>();
    final outOfStock = ctrl.outOfStockProducts;
    final lowStock = ctrl.lowStockProducts;
    final expired = ctrl.expiredProducts;
    final expiringSoon = ctrl.expiringSoonProducts;
    final hasAlerts = outOfStock.isNotEmpty ||
        lowStock.isNotEmpty ||
        expired.isNotEmpty ||
        expiringSoon.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peringatan Stok'),
      ),
      body: !hasAlerts
          ? const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Semua Aman!',
              subtitle: 'Tidak ada peringatan stok atau kedaluwarsa saat ini.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Summary bar ──────────────────────────
                _AlertSummaryBar(
                  outOfStock: outOfStock.length,
                  lowStock: lowStock.length,
                  expired: expired.length,
                  expiringSoon: expiringSoon.length,
                ),
                const SizedBox(height: 20),

                // ─── Out of stock ─────────────────────────
                if (outOfStock.isNotEmpty) ...[
                  _buildSection(
                    context,
                    title: 'Stok Habis',
                    icon: Icons.remove_shopping_cart_rounded,
                    color: AppTheme.dangerColor,
                    products: outOfStock,
                    badgeBuilder: (p) => _StockBadge(
                      text: 'Habis',
                      color: AppTheme.dangerColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ─── Low stock ────────────────────────────
                if (lowStock.isNotEmpty) ...[
                  _buildSection(
                    context,
                    title: 'Stok Menipis',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                    products: lowStock,
                    badgeBuilder: (p) => _StockBadge(
                      text: '${p.stockQuantity} ${p.unit}',
                      color: AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ─── Expired ──────────────────────────────
                if (expired.isNotEmpty) ...[
                  _buildSection(
                    context,
                    title: 'Kedaluwarsa',
                    icon: Icons.event_busy_rounded,
                    color: AppTheme.dangerColor,
                    products: expired,
                    badgeBuilder: (p) => _StockBadge(
                      text: 'Expired ${DateFormat('dd/MM').format(p.expiryDate!)}',
                      color: AppTheme.dangerColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ─── Expiring soon ────────────────────────
                if (expiringSoon.isNotEmpty) ...[
                  _buildSection(
                    context,
                    title: 'Segera Kedaluwarsa',
                    icon: Icons.schedule_rounded,
                    color: Colors.orange,
                    products: expiringSoon,
                    badgeBuilder: (p) {
                      final days = p.daysUntilExpiry!;
                      return _StockBadge(
                        text: days <= 0
                            ? 'Hari ini'
                            : '$days hari lagi',
                        color: Colors.orange,
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Product> products,
    required Widget Function(Product) badgeBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              '$title (${products.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            children: products
                .map((p) => _AlertProductTile(
                      product: p,
                      badge: badgeBuilder(p),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormView(product: p),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Alert Summary Bar ──────────────────────────────────────

class _AlertSummaryBar extends StatelessWidget {
  final int outOfStock;
  final int lowStock;
  final int expired;
  final int expiringSoon;

  const _AlertSummaryBar({
    required this.outOfStock,
    required this.lowStock,
    required this.expired,
    required this.expiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (outOfStock > 0)
          _summaryChip('Habis: $outOfStock', AppTheme.dangerColor),
        if (lowStock > 0)
          _summaryChip('Menipis: $lowStock', AppTheme.warningColor),
        if (expired > 0)
          _summaryChip('Expired: $expired', AppTheme.dangerColor),
        if (expiringSoon > 0)
          _summaryChip('Segera: $expiringSoon', Colors.orange),
      ],
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─── Alert Product Tile ─────────────────────────────────────

class _AlertProductTile extends StatelessWidget {
  final Product product;
  final Widget badge;
  final VoidCallback? onTap;

  const _AlertProductTile({
    required this.product,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty
                      ? product.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatCurrency(product.sellingPrice)} · Min: ${product.minStock} ${product.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            badge,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Stock Badge ────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StockBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
