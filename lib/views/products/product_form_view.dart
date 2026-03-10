import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/theme.dart';
import '../barcode/barcode_scanner_view.dart';

/// Add / Edit product form.
class ProductFormView extends StatefulWidget {
  final Product? product;

  const ProductFormView({super.key, this.product});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _minStockCtrl;
  late String _unit;
  late String _category;
  DateTime? _expiryDate;
  String? _scannedBarcode;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _costCtrl = TextEditingController(
        text: widget.product?.costPrice.toStringAsFixed(0) ?? '');
    _priceCtrl = TextEditingController(
        text: widget.product?.sellingPrice.toStringAsFixed(0) ?? '');
    _stockCtrl = TextEditingController(
        text: widget.product?.stockQuantity.toString() ?? '');
    _minStockCtrl = TextEditingController(
        text: widget.product?.minStock.toString() ?? '5');
    _unit = widget.product?.unit ?? 'pcs';
    _category = widget.product?.category ?? 'Umum';
    _expiryDate = widget.product?.expiryDate;
    _scannedBarcode = widget.product?.barcode;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: Center(
        child: SizedBox(
          width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.5),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            // Product name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                hintText: 'Contoh: Nasi Goreng',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama produk wajib diisi' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Cost & selling price row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Harga Modal',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Harga Jual',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock quantity & min stock row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Stok',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStockCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stok Minimum',
                      hintText: '5',
                      helperText: 'Alert jika stok ≤ ini',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expiry date picker
            InkWell(
              onTap: _pickExpiryDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tanggal Kedaluwarsa',
                  hintText: 'Opsional',
                  suffixIcon: _expiryDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () =>
                              setState(() => _expiryDate = null),
                        )
                      : const Icon(Icons.calendar_today_rounded, size: 20),
                ),
                child: Text(
                  _expiryDate != null
                      ? DateFormat('dd MMM yyyy', 'id_ID')
                          .format(_expiryDate!)
                      : 'Tidak ada',
                  style: TextStyle(
                    color: _expiryDate != null
                        ? null
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Unit dropdown
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: AppConstants.productUnits
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: AppConstants.productCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Umum'),
            ),
            const SizedBox(height: 16),

            // ─── Barcode section ─────────────────────────
            _buildBarcodeSection(),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Produk'),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Widget _buildBarcodeSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBarcode = _scannedBarcode != null && _scannedBarcode!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBarcode
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Barcode Produk',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasBarcode) ...[
            // Show scanned barcode
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scannedBarcode!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _scannedBarcode = null),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Option to re-scan
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _scanPackageBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scan Ulang dari Kemasan'),
              ),
            ),
          ] else ...[
            // Two options: scan or auto-generate
            Text(
              'Scan barcode dari kemasan produk, atau biarkan kosong untuk generate otomatis.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanPackageBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scan dari Kemasan'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scanPackageBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (code == null || !mounted) return;

    // Check if barcode is already used by another product
    final ctrl = context.read<ProductController>();
    final existing = await ctrl.getProductByBarcode(code);
    if (existing != null && existing.id != widget.product?.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode sudah dipakai oleh "${existing.name}"'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() => _scannedBarcode = code);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = context.read<ProductController>();

    if (isEditing) {
      final updated = widget.product!.copyWith(
        name: _nameCtrl.text.trim(),
        costPrice: double.tryParse(_costCtrl.text.replaceAll('.', '')) ?? 0,
        sellingPrice: double.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0,
        stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
        minStock: int.tryParse(_minStockCtrl.text) ?? 5,
        expiryDate: _expiryDate,
        clearExpiryDate: _expiryDate == null,
        unit: _unit,
        category: _category,
        barcode: _scannedBarcode,
      );
      await ctrl.updateProduct(updated);
    } else {
      await ctrl.addProduct(
        name: _nameCtrl.text.trim(),
        costPrice: double.tryParse(_costCtrl.text.replaceAll('.', '')) ?? 0,
        sellingPrice: double.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0,
        stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
        minStock: int.tryParse(_minStockCtrl.text) ?? 5,
        expiryDate: _expiryDate,
        unit: _unit,
        category: _category,
        scannedBarcode: _scannedBarcode,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
