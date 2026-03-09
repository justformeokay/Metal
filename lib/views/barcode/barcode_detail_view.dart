import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import 'barcode_scanner_view.dart';

/// Shows barcode for a product; generates one if none exists.
class BarcodeDetailView extends StatefulWidget {
  final Product product;
  const BarcodeDetailView({super.key, required this.product});

  @override
  State<BarcodeDetailView> createState() => _BarcodeDetailViewState();
}

class _BarcodeDetailViewState extends State<BarcodeDetailView> {
  late Product _product;
  bool _saving = false;
  final GlobalKey _barcodeKey = GlobalKey();
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _generate() async {
    setState(() => _saving = true);
    final ctrl = context.read<ProductController>();
    final code = await ctrl.generateUniqueBarcode();
    final updated = _product.copyWith(barcode: code);
    await ctrl.updateProduct(updated);
    setState(() {
      _product = updated;
      _saving = false;
    });
  }

  /// Scan barcode dari kemasan produk.
  Future<void> _scanFromPackage() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (code == null || !mounted) return;

    final ctrl = context.read<ProductController>();
    final existing = await ctrl.getProductByBarcode(code);
    if (existing != null && existing.id != _product.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode sudah dipakai oleh "${existing.name}"'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final updated = _product.copyWith(barcode: code);
    await ctrl.updateProduct(updated);
    setState(() {
      _product = updated;
      _saving = false;
    });
  }

  Future<void> _removeBarcode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Barcode?'),
        content: const Text('Barcode akan dihapus dari produk ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    final updated = _product.copyWith(clearBarcode: true);
    await context.read<ProductController>().updateProduct(updated);
    setState(() {
      _product = updated;
      _saving = false;
    });
  }

  /// Capture a widget as PNG image and save to gallery.
  Future<void> _captureAndSave(GlobalKey key, String filename) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw 'Failed to convert image';

      await Gal.putImageBytes(byteData.buffer.asUint8List(), name: filename);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$filename tersimpan ke galeri'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBarcode = _product.barcode != null && _product.barcode!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Produk'),
        actions: [
          if (hasBarcode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _removeBarcode,
              tooltip: 'Hapus barcode',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Product info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _product.name.isNotEmpty
                            ? _product.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
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
                          _product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatCurrency(_product.sellingPrice)}  •  Stok: ${_product.stockQuantity} ${_product.unit}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Barcode display or generate button
            if (hasBarcode) ...[
              // Barcode card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // EAN-13 barcode with capture key
                    RepaintBoundary(
                      key: _barcodeKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: BarcodeWidget(
                          barcode: Barcode.ean13(),
                          data: _product.barcode!,
                          width: 260,
                          height: 100,
                          drawText: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 260,
                      child: ElevatedButton.icon(
                        onPressed: () => _captureAndSave(
                          _barcodeKey,
                          '${_product.name}_barcode.png',
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download Barcode'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // QR code version with capture key
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: _product.barcode!,
                              width: 150,
                              height: 150,
                              color: Colors.black87,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: () => _captureAndSave(
                          _qrKey,
                          '${_product.name}_qr.png',
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download QR'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Copy code button
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _product.barcode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode barcode disalin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(_product.barcode!),
              ),
              const SizedBox(height: 12),

              // Regenerate button
              TextButton.icon(
                onPressed: _saving ? null : _generate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Buat Ulang Barcode'),
              ),
            ] else ...[
              // No barcode — generate prompt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark
                    ? Colors.grey.shade900
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 64,
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Barcode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat barcode untuk mempercepat checkout\ndan pengecekan stok produk ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Option 1: Generate barcode baru
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saving ? null : _generate,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 20),
                        label: Text(
                          _saving ? 'Membuat...' : 'Generate Barcode Baru',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Option 2: Scan dari kemasan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _scanFromPackage,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                        label: const Text(
                          'Scan dari Kemasan',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
