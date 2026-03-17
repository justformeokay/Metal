import 'dart:io';

import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import 'product_form_view.dart';

// ── Section colour config ─────────────────────────────────────────────────────

class _Section {
  final String title;
  final String emptyText;
  final IconData icon;
  final Color color;
  const _Section(this.title, this.emptyText, this.icon, this.color);
}

const _secOutOfStock = _Section(
  'Stok Habis',
  'Habis',
  Bootstrap.x_circle,
  Color(0xFFEF4444),
);
const _secLowStock = _Section(
  'Stok Menipis',
  '',
  Bootstrap.exclamation_triangle,
  Color(0xFFF97316),
);
const _secExpired = _Section(
  'Sudah Kedaluwarsa',
  '',
  Bootstrap.calendar_x,
  Color(0xFF8B5CF6),
);
const _secExpiringSoon = _Section(
  'Segera Kedaluwarsa',
  '',
  Bootstrap.clock,
  Color(0xFFF59E0B),
);

// ── View ──────────────────────────────────────────────────────────────────────

class StockAlertsView extends StatelessWidget {
  const StockAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProductController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final outOfStock = ctrl.outOfStockProducts;
    final lowStock = ctrl.lowStockProducts;
    final expired = ctrl.expiredProducts;
    final expiringSoon = ctrl.expiringSoonProducts;
    final total =
        outOfStock.length + lowStock.length + expired.length + expiringSoon.length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF080B14) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF080B14) : const Color(0xFFF4F6FA),
        elevation: 0,
        title: const Text(
          'Peringatan Stok',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: total == 0
          ? const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Semua Aman!',
              subtitle:
                  'Tidak ada peringatan stok atau kedaluwarsa saat ini.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                // ── Summary cards row ─────────────────────
                Row(
                  children: [
                    _SummaryCard(
                      isDark: isDark,
                      count: outOfStock.length,
                      label: 'Habis',
                      icon: Bootstrap.x_circle,
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      isDark: isDark,
                      count: lowStock.length,
                      label: 'Menipis',
                      icon: Bootstrap.exclamation_triangle,
                      color: const Color(0xFFF97316),
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      isDark: isDark,
                      count: expired.length,
                      label: 'Expired',
                      icon: Bootstrap.calendar_x,
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      isDark: isDark,
                      count: expiringSoon.length,
                      label: '< 7 hari',
                      icon: Bootstrap.clock,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Sections ──────────────────────────────
                if (outOfStock.isNotEmpty) ...[
                  _SectionHeader(sec: _secOutOfStock, count: outOfStock.length, isDark: isDark),
                  const SizedBox(height: 10),
                  ...outOfStock.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(
                          product: p,
                          isDark: isDark,
                          sec: _secOutOfStock,
                          badgeText: 'Stok Habis',
                          onTap: () => _goEdit(context, p),
                        ),
                      )),
                  const SizedBox(height: 14),
                ],

                if (lowStock.isNotEmpty) ...[
                  _SectionHeader(sec: _secLowStock, count: lowStock.length, isDark: isDark),
                  const SizedBox(height: 10),
                  ...lowStock.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(
                          product: p,
                          isDark: isDark,
                          sec: _secLowStock,
                          badgeText: '${p.stockQuantity} ${p.unit}',
                          onTap: () => _goEdit(context, p),
                        ),
                      )),
                  const SizedBox(height: 14),
                ],

                if (expired.isNotEmpty) ...[
                  _SectionHeader(sec: _secExpired, count: expired.length, isDark: isDark),
                  const SizedBox(height: 10),
                  ...expired.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(
                          product: p,
                          isDark: isDark,
                          sec: _secExpired,
                          badgeText:
                              'Exp ${DateFormat('dd MMM').format(p.expiryDate!)}',
                          onTap: () => _goEdit(context, p),
                        ),
                      )),
                  const SizedBox(height: 14),
                ],

                if (expiringSoon.isNotEmpty) ...[
                  _SectionHeader(sec: _secExpiringSoon, count: expiringSoon.length, isDark: isDark),
                  const SizedBox(height: 10),
                  ...expiringSoon.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(
                          product: p,
                          isDark: isDark,
                          sec: _secExpiringSoon,
                          badgeText: p.daysUntilExpiry! <= 0
                              ? 'Hari ini!'
                              : '${p.daysUntilExpiry} hari lagi',
                          onTap: () => _goEdit(context, p),
                        ),
                      )),
                ],
              ],
            ),
    );
  }

  void _goEdit(BuildContext context, Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormView(product: p)),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.isDark,
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;
    final isActive = count > 0;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: isDark ? 0.35 : 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05)),
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.12 : 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isActive ? color : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: (isActive ? color : Colors.grey)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isActive ? color : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isActive
                    ? color
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final _Section sec;
  final int count;
  final bool isDark;

  const _SectionHeader({
    required this.sec,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: sec.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(sec.icon, size: 16, color: sec.color),
        const SizedBox(width: 7),
        Text(
          sec.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1F2E),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: sec.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: sec.color,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// ── Alert card (with product image) ──────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final _Section sec;
  final String badgeText;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.product,
    required this.isDark,
    required this.sec,
    required this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;
    final color = sec.color;
    final hasImage =
        product.imagePath != null && product.imagePath!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.07 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Left accent bar ──────────────────
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Product image / avatar ────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: hasImage
                    ? Image.file(
                        File(product.imagePath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _avatarBox(product, color),
                      )
                    : _avatarBox(product, color),
              ),
              const SizedBox(width: 12),

              // ── Info ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1F2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(product.sellingPrice),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Min stok: ${product.minStock} ${product.unit}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Badge + chevron ───────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: color.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Bootstrap.pencil_square,
                        size: 13, color: color),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarBox(Product p, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Center(
        child: Text(
          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

