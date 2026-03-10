import 'package:flutter/material.dart';
import 'package:labaku/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/transaction_controller.dart';
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

          // ─── Product grid ──────────────────────────────
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada produk ditemukan',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
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
                    child: Row(
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                      Text(
                        '${txCtrl.cartItemCount} item',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
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
    final confirmed = await _showPaymentConfirmation(context, txCtrl);
    if (!confirmed) return;

    final tx = await txCtrl.completeSale();
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

  /// Show modern payment confirmation dialog
  Future<bool> _showPaymentConfirmation(
      BuildContext context, TransactionController txCtrl) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            backgroundColor: Colors.transparent,
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
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                      'Pastikan detail pesanan sudah benar',
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
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Item count
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shopping_cart_outlined,
                                      size: 18,
                                      color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jumlah Item',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${txCtrl.cartItemCount} item',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          // Total price
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.payments_rounded,
                                      size: 18,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Total Pembayaran',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                formatCurrency(txCtrl.cartTotal),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ─── Action Buttons ───
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
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
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              backgroundColor:
                                  AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.check_circle_rounded,
                                size: 20),
                            label: const Text(
                              'Bayar Sekarang',
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
        ) ??
        false;
  }
}
