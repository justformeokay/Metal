import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:labaku/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/bank.dart';
import '../../models/member.dart';
import '../../models/product.dart';
import '../../services/bank_service.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../widgets/product_tile.dart';
import '../barcode/barcode_scanner_view.dart';
import '../receipt/receipt_preview_view.dart';

/// Simple POS screen — select products, adjust qty, checkout.
class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  String _search = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prodCtrl = context.watch<ProductController>();
    final txCtrl = context.watch<TransactionController>();

    final filteredProducts = prodCtrl.allProducts.where((p) {
      if (_search.isEmpty) return true;
      return p.name.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan'),
        actions: [
          if (txCtrl.cart.isNotEmpty)
            TextButton.icon(
              onPressed: () => txCtrl.clearCart(),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Kosongkan'),
            ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.5),
          child: Column(
            children: [
              // ─── Search ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.cardDark
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // View toggle button (List/Grid)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _isGridView = false),
                            icon: Icon(
                              Icons.list_rounded,
                              color: !_isGridView ? AppTheme.primaryColor : Colors.grey.shade500,
                            ),
                            tooltip: 'List View',
                            iconSize: 20,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey.shade400,
                          ),
                          IconButton(
                            onPressed: () => setState(() => _isGridView = true),
                            icon: Icon(
                              Icons.grid_3x3_rounded,
                              color: _isGridView ? AppTheme.primaryColor : Colors.grey.shade500,
                            ),
                            tooltip: 'Grid View',
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Barcode scan button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _scanBarcode(context),
                        icon: const Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white),
                        tooltip: 'Scan Barcode',
                      ),
                    ),
                  ],
                ),
              ),

          // ─── Product List/Grid ────────────────────────────
          Expanded(
            child: filteredProducts.isEmpty
                ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada produk ditemukan.\nTambahkan produk baru untuk memulai penjualan pada Tab Produk.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                )
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.57,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductGridCard(product, context, txCtrl);
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ProductTile(
                            product: product,
                            onTap: () => txCtrl.addToCart(product),
                            trailing: product.stockQuantity > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add,
                                        color: AppTheme.primaryColor, size: 20),
                                  )
                                : Text('Habis',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
          ),

          // ─── Cart summary ─────────────────────────────
          if (txCtrl.cart.isNotEmpty) _buildCartPanel(context, txCtrl),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(BuildContext context, TransactionController txCtrl) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cart items
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                itemCount: txCtrl.cart.length,
                itemBuilder: (context, index) {
                  final item = txCtrl.cart[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.product.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Quantity controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _qtyButton(Icons.remove, () {
                                  txCtrl.updateCartQuantity(
                                      index, item.quantity - 1);
                                }),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                _qtyButton(Icons.add, () {
                                  txCtrl.updateCartQuantity(
                                      index, item.quantity + 1);
                                }),
                              ],
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: Text(
                                formatCurrency(item.subtotal),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: item.hasDiscount
                                      ? null
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Discount row
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => _showDiscountDialog(context, txCtrl, index, item),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.hasDiscount
                                        ? AppTheme.dangerColor.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.discount_outlined,
                                        size: 12,
                                        color: item.hasDiscount
                                            ? AppTheme.dangerColor
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.hasDiscount
                                            ? (item.discountPercent > 0
                                                ? (item.product.isDiscountActive &&
                                                        item.product.discountPercent == item.discountPercent &&
                                                        item.product.discountLabel != null &&
                                                        item.product.discountLabel!.isNotEmpty
                                                    ? '${item.product.discountLabel} ${item.discountPercent.toStringAsFixed(0)}%'
                                                    : 'Diskon ${item.discountPercent.toStringAsFixed(0)}%')
                                                : 'Diskon ${formatCurrency(item.discountAmount)}')
                                            : 'Diskon',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: item.hasDiscount
                                              ? AppTheme.dangerColor
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (item.hasDiscount) ...[
                                const SizedBox(width: 6),
                                Text(
                                  formatCurrency(item.product.sellingPrice * item.quantity),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '-${formatCurrency(item.totalDiscount)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.dangerColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // Total & checkout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${txCtrl.cartItemCount} item',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          if (txCtrl.cartDiscountTotal > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${formatCurrency(txCtrl.cartDiscountTotal)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.dangerColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        formatCurrency(txCtrl.cartTotal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _checkout(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Bayar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick a vivid accent colour deterministically from the product id/name.
  Color _cardAccent(Product product) {
    const palette = [
      Color(0xFF10B981), // emerald
      Color(0xFF3B82F6), // blue
      Color(0xFFF59E0B), // amber
      Color(0xFF8B5CF6), // violet
      Color(0xFFEF4444), // red
      Color(0xFF06B6D4), // cyan
      Color(0xFFEC4899), // pink
      Color(0xFF14B8A6), // teal
      Color(0xFFF97316), // orange
      Color(0xFF6366F1), // indigo
    ];
    final hash = product.id.hashCode;
    return palette[hash.abs() % palette.length];
  }

  /// Build a product card for grid view layout
  Widget _buildProductGridCard(
    Product product,
    BuildContext context,
    TransactionController txCtrl,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOutOfStock = product.stockQuantity == 0;
    final isLowStock = !isOutOfStock && product.stockQuantity <= product.minStock;
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;
    final accent = _cardAccent(product);
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isOutOfStock
            ? null
            : () {
                txCtrl.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${product.name} ditambahkan ke keranjang')),
                      ],
                    ),
                    backgroundColor: accent.withOpacity(0.85),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(milliseconds: 1200),
                  ),
                );
              },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardBg,
            border: Border.all(
              color: isOutOfStock
                  ? Colors.grey.withOpacity(0.2)
                  : accent.withOpacity(isDark ? 0.3 : 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isOutOfStock
                    ? Colors.black.withOpacity(0.05)
                    : accent.withOpacity(isDark ? 0.12 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image / icon area ──
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Tinted placeholder bg or image
                      if (hasImage)
                        Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _gridCardImagePlaceholder(isDark, accent),
                        )
                      else
                        _gridCardImagePlaceholder(isDark, accent),

                      // Out-of-stock overlay
                      if (isOutOfStock)
                        Container(color: Colors.black.withOpacity(0.5)),

                      // Bottom gradient — hanya show jika ada image
                      if (hasImage)
                        Positioned(
                          left: 0, right: 0, bottom: 0, height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  cardBg.withOpacity(0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Top-left accent dot stripe
                      Positioned(
                        top: 10, left: 10,
                        child: Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: isOutOfStock ? Colors.grey : accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status badge
                      if (isOutOfStock)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Habis',
                              style: TextStyle(
                                color: Colors.white, fontSize: 9,
                                fontWeight: FontWeight.w800, letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        )
                      else if (isLowStock)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Menipis',
                              style: TextStyle(
                                color: Colors.white, fontSize: 9,
                                fontWeight: FontWeight.w800, letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Details ──
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.25,
                          color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                        ),
                      ),
                      const Spacer(),
                      if (product.isDiscountActive) ...[
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                formatCurrency(product.discountedPrice),
                                style: TextStyle(
                                  color: isOutOfStock
                                      ? Colors.grey
                                      : const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                formatCurrency(product.sellingPrice),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 9,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product.discountPercent.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          formatCurrency(product.sellingPrice),
                          style: TextStyle(
                            color: isOutOfStock ? Colors.grey : accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: -0.3,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'Stok: ${product.stockQuantity} ${product.unit}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),

              // ── Add Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Container(
                  width: double.infinity,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: isOutOfStock
                        ? null
                        : LinearGradient(
                            colors: [accent, accent.withOpacity(0.75)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: isOutOfStock
                        ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
                        : null,
                    border: isOutOfStock
                        ? Border.all(color: Colors.grey.withOpacity(0.2))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.remove_shopping_cart_outlined
                            : Icons.add_rounded,
                        size: 15,
                        color: isOutOfStock ? Colors.grey.shade400 : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutOfStock ? 'Stok Habis' : 'Tambah',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isOutOfStock ? Colors.grey.shade400 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridCardImagePlaceholder(bool isDark, [Color? accent]) {
    final color = accent ?? Colors.grey;
    return Container(
      color: isDark
          ? color.withOpacity(0.08)
          : color.withOpacity(0.06),
      child: Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 44,
          color: isDark
              ? color.withOpacity(0.35)
              : color.withOpacity(0.25),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Builder(
        builder: (context) {
          final isDark =
              Theme.of(context).brightness == Brightness.dark;
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16),
          );
        },
      ),
    );
  }

  /// Open barcode scanner and add scanned product to cart.
  Future<void> _scanBarcode(BuildContext context) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (code == null || !mounted) return;

    final prodCtrl = context.read<ProductController>();
    final txCtrl = context.read<TransactionController>();
    final product = await prodCtrl.getProductByBarcode(code);

    if (product != null) {
      txCtrl.addToCart(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} ditambahkan ke keranjang'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produk dengan barcode "$code" tidak ditemukan'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkout(BuildContext context) async {
    final txCtrl = context.read<TransactionController>();
    final result = await _showPaymentConfirmation(context, txCtrl);
    if (result == null) return;

    final amountPaid = result['amount'] as double;
    final paymentMethod = result['method'] as String;
    final transferBank = result['transferBank'] as String?;
    final transferAccountNumber = result['transferAccountNumber'] as String?;
    final memberId = result['memberId'] as String?;
    final memberDiscountApplied = result['memberDiscountApplied'] as double? ?? 0;

    final tx = await txCtrl.completeSale(
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      transferBank: transferBank,
      transferAccountNumber: transferAccountNumber,
      memberId: memberId,
      memberDiscountApplied: memberDiscountApplied,
    );
    if (tx != null && mounted) {
      // Refresh product stock
      context.read<ProductController>().loadProducts();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewView(transaction: tx),
        ),
      );
    }
  }

  /// Show discount dialog for a cart item.
  void _showDiscountDialog(
    BuildContext context,
    TransactionController txCtrl,
    int index,
    CartItem item,
  ) {
    // 0 = percent, 1 = nominal
    int discountType = item.discountAmount > 0 ? 1 : 0;
    final percentCtrl = TextEditingController(
      text: item.discountPercent > 0 ? item.discountPercent.toStringAsFixed(0) : '',
    );
    final amountCtrl = TextEditingController(
      text: item.discountAmount > 0 ? item.discountAmount.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    'Diskon: ${item.product.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Harga: ${formatCurrency(item.product.sellingPrice)} / ${item.product.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Discount type toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() {
                            discountType = 0;
                            amountCtrl.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: discountType == 0
                                  ? AppTheme.primaryColor
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Persen (%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: discountType == 0
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() {
                            discountType = 1;
                            percentCtrl.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: discountType == 1
                                  ? AppTheme.primaryColor
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Nominal (Rp)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: discountType == 1
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Input field
                  if (discountType == 0)
                    TextField(
                      controller: percentCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Diskon Persen',
                        hintText: 'Contoh: 10',
                        suffixText: '%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Diskon Nominal',
                        hintText: 'Contoh: 5.000',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      // Hapus diskon button
                      if (item.hasDiscount)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              txCtrl.updateCartDiscount(index, percent: 0, amount: 0);
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: AppTheme.dangerColor),
                              foregroundColor: AppTheme.dangerColor,
                            ),
                            child: const Text('Hapus Diskon'),
                          ),
                        ),
                      if (item.hasDiscount) const SizedBox(width: 10),
                      // Terapkan button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            double percent = 0;
                            double amount = 0;

                            if (discountType == 0) {
                              percent = double.tryParse(percentCtrl.text) ?? 0;
                              if (percent > 100) percent = 100;
                            } else {
                              amount = double.tryParse(
                                    amountCtrl.text.replaceAll('.', ''),
                                  ) ?? 0;
                              if (amount > item.product.sellingPrice) {
                                amount = item.product.sellingPrice;
                              }
                            }

                            txCtrl.updateCartDiscount(
                              index,
                              percent: percent,
                              amount: amount,
                            );
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Show modern payment confirmation dialog
  Future<Map<String, dynamic>?> _showPaymentConfirmation(
      BuildContext context, TransactionController txCtrl) async {
    return await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentConfirmationDialog(
        transactionController: txCtrl,
      ),
    );
  }
}

/// A stateful payment confirmation dialog with amount paid input.
class _PaymentConfirmationDialog extends StatefulWidget {
  final TransactionController transactionController;

  const _PaymentConfirmationDialog({
    required this.transactionController,
  });

  @override
  State<_PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<_PaymentConfirmationDialog> {
  late TextEditingController _amountCtrl;
  late TextEditingController _accountNumberCtrl;
  String _selectedPayment = 'Tunai';
  String? _selectedTransferBank;
  late Future<List<Bank>> _banksFuture;
  Member? _selectedMember;
  List<Member> _memberSearchResults = [];
  bool _isSearchingMember = false;
  final TextEditingController _memberSearchCtrl = TextEditingController();
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _accountNumberCtrl = TextEditingController();
    _banksFuture = BankService().getBanks();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountNumberCtrl.dispose();
    _memberSearchCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount => widget.transactionController.cartTotal;

  double get _memberDiscountAmount =>
      _selectedMember != null ? _totalAmount * (_selectedMember!.discountPercent / 100) : 0;

  double get _finalTotal => _totalAmount - _memberDiscountAmount;

  double get _amountPaid {
    if (_amountCtrl.text.isEmpty) return 0;
    return double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
  }

  double get _change => (_amountPaid - _finalTotal).clamp(0, double.infinity);

  bool get _isValid => _amountPaid >= _finalTotal;

  Future<void> _searchMembers(String query) async {
    if (query.length < 2) {
      setState(() {
        _memberSearchResults = [];
        _isSearchingMember = false;
      });
      return;
    }
    setState(() => _isSearchingMember = true);
    final results = await _db.searchMembers(query);
    setState(() {
      _memberSearchResults = results;
      _isSearchingMember = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 360,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.border.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Header Icon ───
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Title ───
                  const Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan jumlah uang yang diterima',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Order Summary ───
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Item count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_cart_outlined,
                                      size: 18,
                                      color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Jumlah Item',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${widget.transactionController.cartItemCount} item',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        // Discount row
                        if (widget.transactionController.cartDiscountTotal > 0) ...[
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.discount_outlined,
                                        size: 18,
                                        color: AppTheme.dangerColor),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Total Diskon',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.dangerColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-${formatCurrency(widget.transactionController.cartDiscountTotal)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.dangerColor,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const Divider(height: 16),

                        // Total price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.attach_money_rounded,
                                      size: 18,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'Subtotal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                formatCurrency(_totalAmount),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Member discount row
                        if (_selectedMember != null && _memberDiscountAmount > 0) ...[
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.card_membership_rounded,
                                        size: 18,
                                        color: AppTheme.accentColor),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Diskon Member (${_selectedMember!.discountPercent.toStringAsFixed(0)}%)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-${formatCurrency(_memberDiscountAmount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Bayar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formatCurrency(_finalTotal),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Member Search ───
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_membership_rounded,
                              size: 18,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Member (Opsional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedMember != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.accentColor,
                                child: Text(
                                  _selectedMember!.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedMember!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Diskon ${_selectedMember!.discountPercent.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() {
                                  _selectedMember = null;
                                  _memberSearchCtrl.clear();
                                  _memberSearchResults = [];
                                }),
                                child: const Icon(Icons.close_rounded,
                                    size: 20, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        TextField(
                          controller: _memberSearchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau telepon member...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _isSearchingMember
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          onChanged: _searchMembers,
                        ),
                        if (_memberSearchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            constraints: const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _memberSearchResults.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final member = _memberSearchResults[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.primaryColor,
                                    child: Text(
                                      member.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${member.phone} • Diskon ${member.discountPercent.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedMember = member;
                                      _memberSearchCtrl.clear();
                                      _memberSearchResults = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ─── Payment Method selector ───
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment_rounded,
                              size: 18,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Tunai',
                          'QRIS',
                          'Gopay',
                          'OVO',
                          'Dana',
                          'Transfer',
                        ]
                            .map((method) => FilterChip(
                                  label: Text(method),
                                  selected: _selectedPayment == method,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedPayment = method;
                                        // For non-cash, clear amount field as it will auto-set to total
                                        if (method != 'Tunai') {
                                          _amountCtrl.clear();
                                        }
                                      });
                                    }
                                  },
                                  backgroundColor: Colors.transparent,
                                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  side: BorderSide(
                                    color: _selectedPayment == method
                                        ? AppTheme.primaryColor
                                        : AppTheme.border.withValues(alpha: 0.3),
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPayment == method
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Transfer Bank Selection (only for Transfer) ───
                  if (_selectedPayment == 'Transfer')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_rounded,
                                size: 18,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Pilih Bank',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<Bank>>(
                          future: _banksFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            final banks = snapshot.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: _selectedTransferBank,
                              isExpanded: true,
                              onChanged: (value) {
                                setState(() => _selectedTransferBank = value);
                              },
                              items: banks.map((bank) {
                                return DropdownMenuItem<String>(
                                  value: bank.kodeBank,
                                  child: Text(
                                    bank.namaBank,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                hintText: 'Pilih bank tujuan',
                                filled: true,
                                isDense: true,
                                fillColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.border.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.border.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // ─── Account Number Input (for Transfer) ───
                        Row(
                          children: [
                            Icon(Icons.numbers_rounded,
                                size: 18,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Nomor Rekening Pengirim',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _accountNumberCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(20),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Contoh: 1234567890',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                            filled: true,
                            isDense: true,
                            fillColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.border.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.border.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  // ─── Amount Paid Input (only for Tunai) ───
                  if (_selectedPayment == 'Tunai')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_rounded,
                                size: 18,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Uang Diterima',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Contoh: 50.000',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                            filled: true,
                            fillColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.border.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.border.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ─── Change Display (only for Tunai) ───
                        if (_amountPaid > 0)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isValid
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isValid
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isValid ? 'Kembalian' : 'Kurang bayar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _isValid ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  _isValid
                                      ? formatCurrency(_change)
                                      : '-${formatCurrency((_finalTotal - _amountPaid).abs())}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _isValid ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // ─── Action Buttons ───
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: AppTheme.border,
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirm Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_selectedPayment != 'Tunai' || _isValid) &&
                                  (_selectedPayment != 'Transfer' ||
                                      (_selectedTransferBank != null &&
                                          _accountNumberCtrl.text.isNotEmpty))
                              ? () {
                                  // For non-cash, auto-set amount to total
                                  final finalAmount = _selectedPayment != 'Tunai'
                                      ? _finalTotal
                                      : _amountPaid;

                                  Navigator.pop(
                                    context,
                                    {
                                      'amount': finalAmount,
                                      'method': _selectedPayment,
                                      'transferBank': _selectedTransferBank,
                                      'transferAccountNumber': _accountNumberCtrl.text,
                                      'memberId': _selectedMember?.id,
                                      'memberDiscountApplied': _memberDiscountAmount,
                                    },
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: (_selectedPayment != 'Tunai' || _isValid) &&
                                    (_selectedPayment != 'Transfer' ||
                                        (_selectedTransferBank != null &&
                                            _accountNumberCtrl.text.isNotEmpty))
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.check_circle_rounded,
                              size: 20),
                          label: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
