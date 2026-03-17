import 'dart:io';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../barcode/barcode_scanner_view.dart';

/// Add / Edit product form — Metal-style redesign.
class ProductFormView extends StatefulWidget {
  final Product? product;

  const ProductFormView({super.key, this.product});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView>
    with SingleTickerProviderStateMixin {
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
  String? _imagePath;

  // ── Discount state ──────────────────────────────────────
  bool _discountEnabled = false;
  late TextEditingController _discountLabelCtrl;
  double _discountPercent = 0;
  late TextEditingController _discountPercentCtrl;
  DateTime? _discountStartDate;
  DateTime? _discountEndDate;

  bool _saving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _costCtrl = TextEditingController(
        text: p?.costPrice.toStringAsFixed(0) ?? '');
    _priceCtrl = TextEditingController(
        text: p?.sellingPrice.toStringAsFixed(0) ?? '');
    _stockCtrl = TextEditingController(
        text: p?.stockQuantity.toString() ?? '');
    _minStockCtrl = TextEditingController(
        text: p?.minStock.toString() ?? '5');
    _unit = p?.unit ?? 'pcs';
    _category = p?.category ?? 'Umum';
    _expiryDate = p?.expiryDate;
    _scannedBarcode = p?.barcode;
    _imagePath = p?.imagePath;

    _discountEnabled = p?.discountEnabled ?? false;
    _discountLabelCtrl = TextEditingController(text: p?.discountLabel ?? '');
    _discountPercent = p?.discountPercent ?? 0;
    _discountPercentCtrl = TextEditingController(
        text: _discountPercent > 0
            ? _discountPercent.toStringAsFixed(0)
            : '');
    _discountStartDate = p?.discountStartDate;
    _discountEndDate = p?.discountEndDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _discountLabelCtrl.dispose();
    _discountPercentCtrl.dispose();
    super.dispose();
  }

  // ── Calculated discounted price preview ─────────────────
  double get _previewSellingPrice {
    return double.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0;
  }

  double get _previewDiscountedPrice {
    if (!_discountEnabled || _discountPercent <= 0) return _previewSellingPrice;
    return _previewSellingPrice * (1 - _discountPercent / 100);
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? const Color(0xFF080B14) : const Color(0xFFF4F6FA);
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Bootstrap.chevron_left,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Produk' : 'Tambah Produk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.55),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Photo hero ───────────────────────────
                _buildPhotoSection(isDark, cardBg),
                const SizedBox(height: 16),

                // ── Info dasar ───────────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  accentColor: AppTheme.primaryColor,
                  icon: Bootstrap.box_seam,
                  title: 'Info Produk',
                  child: Column(
                    children: [
                      _buildField(
                        controller: _nameCtrl,
                        label: 'Nama Produk',
                        hint: 'Contoh: Nasi Goreng Spesial',
                        isDark: isDark,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      // Categories
                      _buildChipSelector(
                        label: 'Kategori',
                        options: AppConstants.productCategories,
                        selected: _category,
                        onSelect: (v) => setState(() => _category = v),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      // Unit
                      _buildChipSelector(
                        label: 'Satuan',
                        options: AppConstants.productUnits,
                        selected: _unit,
                        onSelect: (v) => setState(() => _unit = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Harga ────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  accentColor: const Color(0xFF10B981),
                  icon: Bootstrap.currency_dollar,
                  title: 'Harga',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _costCtrl,
                          label: 'Harga Modal',
                          hint: '0',
                          isDark: isDark,
                          prefixText: 'Rp ',
                          inputType: TextInputType.number,
                          formatters: [CurrencyInputFormatter()],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _priceCtrl,
                          label: 'Harga Jual',
                          hint: '0',
                          isDark: isDark,
                          prefixText: 'Rp ',
                          inputType: TextInputType.number,
                          formatters: [CurrencyInputFormatter()],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stok ─────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  accentColor: const Color(0xFF8B5CF6),
                  icon: Bootstrap.stack,
                  title: 'Stok',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _stockCtrl,
                          label: 'Jumlah Stok',
                          hint: '0',
                          isDark: isDark,
                          inputType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _minStockCtrl,
                          label: 'Stok Min. Alert',
                          hint: '5',
                          isDark: isDark,
                          inputType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Kedaluwarsa ──────────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  accentColor: const Color(0xFFF59E0B),
                  icon: Bootstrap.calendar3,
                  title: 'Kedaluwarsa',
                  trailing: _expiryDate != null
                      ? GestureDetector(
                          onTap: () => setState(() => _expiryDate = null),
                          child: Icon(Bootstrap.x_circle,
                              size: 16,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400),
                        )
                      : null,
                  child: GestureDetector(
                    onTap: _pickExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _expiryDate != null
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Bootstrap.calendar_check,
                            size: 16,
                            color: _expiryDate != null
                                ? const Color(0xFFF59E0B)
                                : (isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _expiryDate != null
                                ? DateFormat('dd MMM yyyy', 'id_ID')
                                    .format(_expiryDate!)
                                : 'Pilih tanggal (opsional)',
                            style: TextStyle(
                              fontSize: 14,
                              color: _expiryDate != null
                                  ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B))
                                  : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Barcode ──────────────────────────────
                _buildBarcodeSection(isDark, cardBg),
                const SizedBox(height: 12),

                // ── Diskon ───────────────────────────────
                _buildDiscountSection(isDark, cardBg),
                const SizedBox(height: 28),

                // ── Save button ──────────────────────────
                _buildSaveButton(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION BUILDERS
  // ─────────────────────────────────────────────────────────

  Widget _buildDiscountSection(bool isDark, Color cardBg) {
    final accentColor = const Color(0xFFF59E0B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _discountEnabled
              ? accentColor.withValues(alpha: 0.4)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06)),
          width: _discountEnabled ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Toggle header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (_discountEnabled
                            ? accentColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06)))
                        .withValues(
                            alpha: _discountEnabled ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Bootstrap.tag,
                    size: 16,
                    color: _discountEnabled
                        ? accentColor
                        : (isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diskon Produk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Promo harga otomatis saat checkout',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Switch(
                  value: _discountEnabled,
                  onChanged: (v) => setState(() => _discountEnabled = v),
                  activeColor: accentColor,
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return accentColor.withValues(alpha: 0.3);
                    }
                    return isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1);
                  }),
                ),
              ],
            ),
          ),

          // ── Expandable fields ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _discountEnabled
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label promo
                            _buildField(
                              controller: _discountLabelCtrl,
                              label: 'Label Promo',
                              hint: 'Contoh: Flash Sale, Promo Lebaran',
                              isDark: isDark,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 14),

                            // Percent slider + input
                            Row(
                              children: [
                                Text(
                                  'Besar Diskon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 68,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: accentColor
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        child: TextField(
                                          controller: _discountPercentCtrl,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: accentColor,
                                          ),
                                          onChanged: (v) {
                                            final pct =
                                                double.tryParse(v) ?? 0;
                                            setState(() => _discountPercent =
                                                pct.clamp(0, 100));
                                          },
                                        ),
                                      ),
                                      Text(
                                        '%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _discountPercent.clamp(0, 100),
                              min: 0,
                              max: 100,
                              divisions: 100,
                              activeColor: accentColor,
                              inactiveColor:
                                  accentColor.withValues(alpha: 0.15),
                              onChanged: (v) => setState(() {
                                _discountPercent = v;
                                _discountPercentCtrl.text =
                                    v.toStringAsFixed(0);
                              }),
                            ),

                            // Calculated price preview
                            if (_previewSellingPrice > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          accentColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Bootstrap.calculator,
                                        size: 14,
                                        color: accentColor),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Harga setelah diskon',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              formatCurrency(
                                                  _previewDiscountedPrice),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: accentColor,
                                              ),
                                            ),
                                            if (_discountPercent > 0) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                formatCurrency(
                                                    _previewSellingPrice),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade400,
                                                  decoration:
                                                      TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Date range
                            Text(
                              'Periode Diskon',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTile(
                                    label: 'Mulai',
                                    date: _discountStartDate,
                                    isDark: isDark,
                                    accentColor: accentColor,
                                    onTap: () => _pickDiscountDate(isStart: true),
                                    onClear: () => setState(
                                        () => _discountStartDate = null),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Icon(Bootstrap.arrow_right,
                                      size: 14,
                                      color: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400),
                                ),
                                Expanded(
                                  child: _buildDateTile(
                                    label: 'Selesai',
                                    date: _discountEndDate,
                                    isDark: isDark,
                                    accentColor: accentColor,
                                    onTap: () =>
                                        _pickDiscountDate(isStart: false),
                                    onClear: () =>
                                        setState(() => _discountEndDate = null),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Biarkan kosong agar diskon berlaku tanpa batas waktu',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required bool isDark,
    required Color accentColor,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: date != null
              ? accentColor.withValues(alpha: 0.08)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null
                ? accentColor.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy', 'id_ID').format(date)
                        : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          date != null ? FontWeight.w600 : FontWeight.normal,
                      color: date != null
                          ? (isDark
                              ? Colors.white
                              : const Color(0xFF1E293B))
                          : (isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Bootstrap.x,
                    size: 12,
                    color: isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    final color = _discountEnabled
        ? const Color(0xFFF59E0B)
        : AppTheme.accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _saving ? null : _save,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEditing
                              ? Bootstrap.check2_circle
                              : Bootstrap.plus_circle,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Simpan Perubahan' : 'Tambah Produk',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────

  Widget _buildChipSelector({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((o) {
            final isSelected = o == selected;
            return GestureDetector(
              onTap: () => onSelect(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1)),
                  ),
                ),
                child: Text(
                  o,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    String? prefixText,
    TextInputType inputType = TextInputType.text,
    List<dynamic> formatters = const [],
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: formatters.cast(),
      validator: validator,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppTheme.primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        labelStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PHOTO SECTION
  // ─────────────────────────────────────────────────────────

  Widget _buildPhotoSection(bool isDark, Color cardBg) {
    final hasImage = _imagePath != null && File(_imagePath!).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.file(
                File(_imagePath!),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _photoButton(
                      icon: Bootstrap.image,
                      label: 'Ganti (Galeri)',
                      isDark: isDark,
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _photoButton(
                      icon: Bootstrap.camera,
                      label: 'Kamera',
                      isDark: isDark,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _photoButton(
                    icon: Bootstrap.trash,
                    label: 'Hapus',
                    isDark: isDark,
                    danger: true,
                    onTap: () => setState(() => _imagePath = null),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Bootstrap.image,
                        size: 28, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Foto Produk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tambahan opsional untuk tampilan produk',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _photoButton(
                        icon: Bootstrap.images,
                        label: 'Galeri',
                        isDark: isDark,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(width: 10),
                      _photoButton(
                        icon: Bootstrap.camera,
                        label: 'Kamera',
                        isDark: isDark,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger
        ? AppTheme.dangerColor
        : AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BARCODE SECTION
  // ─────────────────────────────────────────────────────────

  Widget _buildBarcodeSection(bool isDark, Color cardBg) {
    final hasBarcode = _scannedBarcode != null && _scannedBarcode!.isNotEmpty;

    return _SectionCard(
      isDark: isDark,
      cardBg: cardBg,
      accentColor: const Color(0xFF06B6D4),
      icon: Bootstrap.upc_scan,
      title: 'Barcode Produk',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBarcode) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Bootstrap.check_circle,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scannedBarcode!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _scannedBarcode = null),
                    child: const Icon(Bootstrap.x_circle,
                        size: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _barcodeButton(isDark: isDark, label: 'Scan Ulang'),
          ] else ...[
            Text(
              'Scan barcode dari kemasan, atau biarkan kosong untuk generate otomatis.',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            _barcodeButton(isDark: isDark, label: 'Scan dari Kemasan'),
          ],
        ],
      ),
    );
  }

  Widget _barcodeButton({required bool isDark, required String label}) {
    return GestureDetector(
      onTap: _scanPackageBarcode,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Bootstrap.upc_scan,
                size: 16, color: Color(0xFF06B6D4)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF06B6D4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // LOGIC
  // ─────────────────────────────────────────────────────────

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _pickDiscountDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_discountStartDate ?? now)
        : (_discountEndDate ??
            (_discountStartDate?.add(const Duration(days: 7)) ??
                now.add(const Duration(days: 7))));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isStart
          ? now.subtract(const Duration(days: 365))
          : (_discountStartDate ?? now),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _discountStartDate = picked;
          if (_discountEndDate != null &&
              _discountEndDate!.isBefore(picked)) {
            _discountEndDate = null;
          }
        } else {
          _discountEndDate = picked;
        }
      });
    }
  }

  Future<void> _scanPackageBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (code == null || !mounted) return;

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
    setState(() => _saving = true);

    try {
      final ctrl = context.read<ProductController>();

      final discountEnabled = _discountEnabled && _discountPercent > 0;

      if (isEditing) {
        final updated = widget.product!.copyWith(
          name: _nameCtrl.text.trim(),
          costPrice:
              double.tryParse(_costCtrl.text.replaceAll('.', '')) ?? 0,
          sellingPrice:
              double.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0,
          stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
          minStock: int.tryParse(_minStockCtrl.text) ?? 5,
          expiryDate: _expiryDate,
          clearExpiryDate: _expiryDate == null,
          unit: _unit,
          category: _category,
          barcode: _scannedBarcode,
          imagePath: _imagePath,
          clearImagePath: _imagePath == null,
          discountEnabled: discountEnabled,
          discountLabel: _discountLabelCtrl.text.trim().isEmpty
              ? null
              : _discountLabelCtrl.text.trim(),
          clearDiscountLabel: _discountLabelCtrl.text.trim().isEmpty,
          discountPercent: discountEnabled ? _discountPercent : 0,
          discountStartDate: _discountStartDate,
          clearDiscountStartDate: _discountStartDate == null,
          discountEndDate: _discountEndDate,
          clearDiscountEndDate: _discountEndDate == null,
        );
        await ctrl.updateProduct(updated);
      } else {
        await ctrl.addProduct(
          name: _nameCtrl.text.trim(),
          costPrice:
              double.tryParse(_costCtrl.text.replaceAll('.', '')) ?? 0,
          sellingPrice:
              double.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0,
          stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
          minStock: int.tryParse(_minStockCtrl.text) ?? 5,
          expiryDate: _expiryDate,
          unit: _unit,
          category: _category,
          scannedBarcode: _scannedBarcode,
          imagePath: _imagePath,
          discountEnabled: discountEnabled,
          discountLabel: _discountLabelCtrl.text.trim().isEmpty
              ? null
              : _discountLabelCtrl.text.trim(),
          discountPercent: discountEnabled ? _discountPercent : 0,
          discountStartDate: _discountStartDate,
          discountEndDate: _discountEndDate,
        );
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final appDir = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(appDir.path, 'product_images'));
    if (!destDir.existsSync()) destDir.createSync(recursive: true);

    final ext = p.extension(picked.path).isNotEmpty
        ? p.extension(picked.path)
        : '.jpg';
    final fileName =
        '${widget.product?.id ?? DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(destDir.path, fileName);
    await File(picked.path).copy(destPath);

    setState(() => _imagePath = destPath);
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION CARD COMPONENT
// ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color accentColor;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.isDark,
    required this.cardBg,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

