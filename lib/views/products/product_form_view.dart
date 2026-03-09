import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

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
      body: Form(
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = context.read<ProductController>();

    if (isEditing) {
      final updated = widget.product!.copyWith(
        name: _nameCtrl.text.trim(),
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        sellingPrice: double.tryParse(_priceCtrl.text) ?? 0,
        stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
        minStock: int.tryParse(_minStockCtrl.text) ?? 5,
        expiryDate: _expiryDate,
        clearExpiryDate: _expiryDate == null,
        unit: _unit,
        category: _category,
      );
      await ctrl.updateProduct(updated);
    } else {
      await ctrl.addProduct(
        name: _nameCtrl.text.trim(),
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        sellingPrice: double.tryParse(_priceCtrl.text) ?? 0,
        stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
        minStock: int.tryParse(_minStockCtrl.text) ?? 5,
        expiryDate: _expiryDate,
        unit: _unit,
        category: _category,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
