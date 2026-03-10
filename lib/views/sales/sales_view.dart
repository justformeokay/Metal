import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:labaku/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/transaction_controller.dart';
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
                                                ? 'Diskon ${item.discountPercent.toStringAsFixed(0)}%'
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

    final tx = await txCtrl.completeSale(
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
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
  String _selectedPayment = 'Tunai';

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount => widget.transactionController.cartTotal;

  double get _amountPaid {
    if (_amountCtrl.text.isEmpty) return 0;
    return double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
  }

  double get _change => (_amountPaid - _totalAmount).clamp(0, double.infinity);

  bool get _isValid => _amountPaid >= _totalAmount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 400,
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
                                      'Total',
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
                      ],
                    ),
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
                  const SizedBox(height: 24),

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
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

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
                                      : '-${formatCurrency((_totalAmount - _amountPaid).abs())}',
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
                  const SizedBox(height: 28),

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
                          onPressed: (_selectedPayment != 'Tunai' || _isValid)
                              ? () {
                                  // For non-cash, auto-set amount to total
                                  final finalAmount = _selectedPayment != 'Tunai'
                                      ? _totalAmount
                                      : _amountPaid;

                                  Navigator.pop(
                                    context,
                                    {
                                      'amount': finalAmount,
                                      'method': _selectedPayment,
                                    },
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: (_selectedPayment != 'Tunai' || _isValid)
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
