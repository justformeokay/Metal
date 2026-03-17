import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/printer_settings.dart';
import '../models/transaction.dart';
import '../models/store_model.dart';
import '../utils/formatters.dart';

/// Service for Bluetooth Classic thermal printer operations.
/// Singleton — connection persists across pages.
class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._();

  bool _connected = false;
  String? _connectedName;

  bool get isConnected => _connected;
  String? get connectedDeviceName => _connectedName;

  /// Get list of already-paired Bluetooth devices.
  Future<List<BluetoothInfo>> getPairedDevices() async {
    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) {
      throw Exception('Bluetooth tidak aktif. Silakan aktifkan Bluetooth.');
    }

    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) {
      throw Exception('Izin Bluetooth belum diberikan.');
    }

    return await PrintBluetoothThermal.pairedBluetooths;
  }

  /// Connect to a paired Bluetooth printer by MAC address.
  Future<void> connect(BluetoothInfo device) async {
    await disconnect();

    final result = await PrintBluetoothThermal.connect(
      macPrinterAddress: device.macAdress,
    );

    if (!result) {
      throw Exception('Gagal menghubungkan ke ${device.name}. Pastikan printer menyala.');
    }

    _connected = true;
    _connectedName = device.name;
  }

  /// Disconnect from the current printer.
  Future<void> disconnect() async {
    if (_connected) {
      try {
        await PrintBluetoothThermal.disconnect;
      } catch (_) {}
    }
    _connected = false;
    _connectedName = null;
  }

  /// Refresh connection status from the native side.
  Future<bool> refreshConnectionStatus() async {
    _connected = await PrintBluetoothThermal.connectionStatus;
    if (!_connected) {
      _connectedName = null;
    }
    return _connected;
  }

  /// Print receipt for a transaction.
  Future<void> printReceipt({
    required SalesTransaction transaction,
    required StoreModel store,
    String? memberName,
  }) async {
    if (!_connected) {
      throw Exception('Printer belum terhubung.');
    }

    final settings = await PrinterSettings.load();

    final bytes = await _generateReceiptBytes(
      transaction: transaction,
      store: store,
      memberName: memberName,
      settings: settings,
    );

    await _writeBytes(bytes);

    if (settings.printDuplicate) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _writeBytes(bytes);
    }
  }

  /// Print raw ESC/POS bytes directly.
  Future<void> printRawBytes(List<int> bytes) async {
    if (!_connected) {
      throw Exception('Printer belum terhubung.');
    }
    await _writeBytes(bytes);
  }

  /// Write bytes to printer via Bluetooth Classic SPP.
  /// Sends data in chunks to avoid Bluetooth buffer overflow.
  Future<void> _writeBytes(List<int> bytes) async {
    const chunkSize = 500;
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
      final chunk = bytes.sublist(i, end);
      final result = await PrintBluetoothThermal.writeBytes(chunk);
      if (!result) {
        _connected = false;
        _connectedName = null;
        throw Exception('Gagal mengirim data ke printer. Koneksi terputus.');
      }
      // Small delay between chunks to let printer process
      if (end < bytes.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// Load logo image from a URL or local file path. Returns null on failure.
  Future<img.Image?> _loadLogoImage(String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    try {
      List<int> bytes;
      if (logoUrl.startsWith('http')) {
        final response = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return null;
        bytes = response.bodyBytes;
      } else {
        final file = File(logoUrl);
        if (!file.existsSync()) return null;
        bytes = await file.readAsBytes();
      }
      return img.decodeImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  /// Generate raw ESC/POS raster bytes for an image (GS v 0).
  /// Bypasses esc_pos_utils_plus's buggy _toRasterFormat.
  List<int> _imageToEscPos(img.Image srcImage, {PosAlign align = PosAlign.center}) {
    // Convert to grayscale
    final grayImg = img.grayscale(img.Image.from(srcImage));
    final int widthPx = grayImg.width;
    final int heightPx = grayImg.height;
    // Width in bytes (8 pixels per byte)
    final int widthBytes = (widthPx + 7) ~/ 8;

    // Build raster data: 1 bit per pixel, MSB first, black = 1
    final rasterData = <int>[];
    for (int y = 0; y < heightPx; y++) {
      for (int byteX = 0; byteX < widthBytes; byteX++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final int x = byteX * 8 + bit;
          if (x < widthPx) {
            final pixel = grayImg.getPixel(x, y);
            // Luminance: use red channel (already grayscale, all channels equal)
            final int lum = pixel.r.toInt();
            // Black pixel = luminance < 128 → set bit to 1
            if (lum < 128) {
              byte |= (0x80 >> bit);
            }
          }
          // Pixels beyond image width stay 0 (white)
        }
        rasterData.add(byte);
      }
    }

    final List<int> bytes = [];

    // Set alignment: ESC a n
    final int alignByte = align == PosAlign.left ? 0 : (align == PosAlign.right ? 2 : 1);
    bytes.addAll([0x1B, 0x61, alignByte]);

    // GS v 0 — print raster bit image
    // 1B 76 30 m xL xH yL yH [data]
    bytes.addAll([
      0x1D, 0x76, 0x30,
      0, // m = 0 (normal density)
      widthBytes & 0xFF, (widthBytes >> 8) & 0xFF, // xL xH
      heightPx & 0xFF, (heightPx >> 8) & 0xFF, // yL yH
    ]);
    bytes.addAll(rasterData);

    return bytes;
  }

  /// Sanitize text for ESC/POS printer (ASCII-safe).
  String _sanitize(String text) {
    return text
        .replaceAll('\u2014', '-')  // em dash
        .replaceAll('\u2013', '-')  // en dash
        .replaceAll('\u2018', "'") // left single quote
        .replaceAll('\u2019', "'") // right single quote
        .replaceAll('\u201C', '"') // left double quote
        .replaceAll('\u201D', '"') // right double quote
        .replaceAll('\u2026', '...') // ellipsis
        .replaceAll(RegExp(r'[^\x00-\x7F]'), ''); // strip remaining non-ASCII
  }

  /// Generate ESC/POS receipt bytes using settings.
  Future<List<int>> _generateReceiptBytes({
    required SalesTransaction transaction,
    required StoreModel store,
    String? memberName,
    required PrinterSettings settings,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = settings.paperSize == '80mm'
        ? PaperSize.mm80
        : PaperSize.mm58;
    final generator = Generator(paper, profile);
    List<int> bytes = [];

    // Font size based on settings
    final headerHeight = settings.fontScale >= 2
        ? PosTextSize.size2
        : PosTextSize.size1;

    // Top margin
    if (settings.marginTop > 0) {
      bytes += generator.feed(settings.marginTop.toInt().clamp(0, 10));
    }

    // ─── Logo ────────────────────────────────────
    if (settings.showLogo && store.logoUrl != null && store.logoUrl!.isNotEmpty) {
      final logoImg = await _loadLogoImage(store.logoUrl);
      if (logoImg != null) {
        // Target ~50% of paper width for a compact logo
        final halfWidth = settings.paperSize == '80mm' ? 288 : 192;
        int targetW = logoImg.width > halfWidth ? halfWidth : logoImg.width;
        // Round down to multiple of 8
        targetW = (targetW ~/ 8) * 8;
        if (targetW < 8) targetW = 8;

        final resized = img.copyResize(
          logoImg,
          width: targetW,
          interpolation: img.Interpolation.average,
        );
        // Use custom raster generation (bypasses library bugs)
        bytes += _imageToEscPos(resized, align: PosAlign.center);
        bytes += generator.feed(1);
      }
    }

    // ─── Header ─────────────────────────────────
    bytes += generator.text(
      _sanitize(store.storeName),
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: headerHeight,
      ),
    );

    if (settings.showAddress && store.address != null && store.address!.isNotEmpty) {
      bytes += generator.text(
        _sanitize(store.address!),
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (settings.showPhone && store.phone != null && store.phone!.isNotEmpty) {
      bytes += generator.text(
        _sanitize(store.phone!),
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (settings.showDescription && store.description != null && store.description!.isNotEmpty) {
      bytes += generator.text(
        _sanitize(store.description!),
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr(ch: '=');

    // ─── Customer Name ──────────────────────────
    if (transaction.customerName != null && transaction.customerName!.isNotEmpty) {
      bytes += generator.text(
        'Kepada: ${_sanitize(transaction.customerName!)}',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
    }

    // ─── Date & Transaction ID ──────────────────
    if (settings.showDateTime) {
      bytes += generator.text(
        formatDateTime(transaction.date),
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    if (settings.showTransactionId) {
      bytes += generator.text(
        '#${transaction.id.substring(0, 8).toUpperCase()}',
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    bytes += generator.hr();

    // ─── Items ──────────────────────────────────
    for (final item in transaction.items) {
      bytes += generator.text(
        _sanitize(item.productName),
        styles: const PosStyles(bold: true),
      );
      bytes += generator.row([
        PosColumn(
          text: '  ${item.quantity} x ${formatCurrency(item.unitPrice)}',
          width: 7,
        ),
        PosColumn(
          text: formatCurrency(item.subtotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (item.hasDiscount) {
        final discLabel = item.discountPercent > 0
            ? '  Diskon ${item.discountPercent.toStringAsFixed(0)}%'
            : '  Diskon ${formatCurrency(item.discountAmount)}/item';
        bytes += generator.row([
          PosColumn(text: discLabel, width: 7),
          PosColumn(
            text: '-${formatCurrency(item.totalDiscount)}',
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }

    bytes += generator.hr();

    // ─── Discount Total ─────────────────────────
    if (transaction.totalDiscount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Total Diskon', width: 7),
        PosColumn(
          text: '-${formatCurrency(transaction.totalDiscount)}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // ─── Member Discount ────────────────────────
    if (settings.showMemberInfo && transaction.memberDiscountApplied > 0 && memberName != null) {
      bytes += generator.row([
        PosColumn(text: 'Diskon Member', width: 7),
        PosColumn(
          text: '-${formatCurrency(transaction.memberDiscountApplied)}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // ─── Total ──────────────────────────────────
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 5,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: formatCurrency(transaction.totalAmount),
        width: 7,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.hr();

    // ─── Payment Info ───────────────────────────
    if (settings.showPaymentDetails && transaction.amountPaid > 0) {
      bytes += generator.row([
        PosColumn(text: 'Bayar', width: 6),
        PosColumn(
          text: formatCurrency(transaction.amountPaid),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Kembali', width: 6),
        PosColumn(
          text: formatCurrency(transaction.change),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'Metode', width: 6),
      PosColumn(
        text: _sanitize(transaction.paymentMethod),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr(ch: '=');

    // ─── Footer ─────────────────────────────────
    if (settings.footerText.isNotEmpty) {
      bytes += generator.text(
        _sanitize(settings.footerText),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (settings.footerSecondLine.isNotEmpty) {
      bytes += generator.text(
        _sanitize(settings.footerSecondLine),
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Bottom margin
    if (settings.marginBottom > 0) {
      bytes += generator.feed(settings.marginBottom.toInt().clamp(0, 10));
    }

    // Extra feed so footer text doesn't get cut when tearing
    bytes += generator.feed(settings.feedLinesAfter + 3);
    if (settings.autoCut) bytes += generator.cut();

    return bytes;
  }
}
