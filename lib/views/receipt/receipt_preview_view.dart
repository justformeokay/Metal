import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bank.dart';
import '../../models/member.dart';
import '../../models/store_model.dart';
import '../../models/transaction.dart';
import '../../services/bank_service.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';
import '../../services/store_service.dart';
import '../receipt/bluetooth_printer_view.dart';

/// Receipt preview screen that looks like a real printed receipt.
class ReceiptPreviewView extends StatefulWidget {
  final SalesTransaction transaction;

  const ReceiptPreviewView({super.key, required this.transaction});

  @override
  State<ReceiptPreviewView> createState() => _ReceiptPreviewViewState();
}

class _ReceiptPreviewViewState extends State<ReceiptPreviewView> {
  final StoreService _storeService = StoreService();
  final GlobalKey _receiptKey = GlobalKey();
  StoreModel? _userStore;
  Bank? _transferBank;
  String? _logoPath;
  Member? _member;
  bool _isLoading = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadUserStore();
    _loadTransferBank();
    _loadLogoPath();
    _loadMember();
  }

  Future<void> _loadMember() async {
    if (widget.transaction.memberId != null) {
      final member = await DatabaseService().getMemberById(widget.transaction.memberId!);
      if (mounted) setState(() => _member = member);
    }
  }

  Future<void> _loadLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('store_logo_path');
    if (mounted) {
      setState(() => _logoPath = path);
    }
  }

  Future<void> _loadTransferBank() async {
    if (widget.transaction.paymentMethod == 'Transfer' &&
        widget.transaction.transferBank != null) {
      final bank = await BankService()
          .getBankByCodeAsync(widget.transaction.transferBank!);
      if (mounted) setState(() => _transferBank = bank);
    }
  }

  Future<void> _loadUserStore() async {
    final result = await _storeService.getMyStores();
    if (result.stores.isNotEmpty && mounted) {
      setState(() {
        _userStore = result.stores.first;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeName = _isLoading ? 'Memuat...' : (_userStore?.storeName ?? 'LabaKu');
    final storeAddress = _isLoading ? '' : (_userStore?.address ?? '');
    final storePhone = _isLoading ? '' : (_userStore?.phone ?? '');
    final storeDescription = _isLoading ? '' : (_userStore?.description ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Cetak Struk',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BluetoothPrinterView(transaction: widget.transaction),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: RepaintBoundary(
            key: _receiptKey,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ─── Header ──────────────────────────────
                if (_logoPath != null && File(_logoPath!).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: 160,
                      child: Image.file(
                        File(_logoPath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (storeAddress.isNotEmpty)
                  Text(
                    storeAddress,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                if (storePhone.isNotEmpty)
                  Text(
                    storePhone,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                if (storeDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      storeDescription,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 12),
                _dashedDivider(),
                const SizedBox(height: 8),

                // Date & ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDateTime(widget.transaction.date),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    Text(
                      '#${widget.transaction.id.substring(0, 8).toUpperCase()}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),

                // ─── Items ───────────────────────────────
                ...widget.transaction.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '  ${item.quantity} x ${formatCurrency(item.unitPrice)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                              Text(
                                formatCurrency(item.subtotal),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (item.hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.discountPercent > 0
                                        ? '  Diskon ${item.discountPercent.toStringAsFixed(0)}%'
                                        : '  Diskon ${formatCurrency(item.discountAmount)}/item',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    '-${formatCurrency(item.totalDiscount)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )),

                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),

                // ─── Discount Total ──────────────────────
                if (widget.transaction.totalDiscount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Diskon',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '-${formatCurrency(widget.transaction.totalDiscount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── Member Discount ─────────────────────
                if (widget.transaction.memberDiscountApplied > 0 && _member != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Diskon Member (${_member!.name})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '-${formatCurrency(widget.transaction.memberDiscountApplied)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── Total ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      formatCurrency(widget.transaction.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _dashedDivider(),
                const SizedBox(height: 12),

                // ─── Payment Information ─────────────────
                if (widget.transaction.amountPaid > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Uang Diterima',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        formatCurrency(widget.transaction.amountPaid),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kembalian',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        formatCurrency(widget.transaction.change),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      _buildPaymentMethodWidget(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dashedDivider(),
                  const SizedBox(height: 12),
                ],

                // ─── Footer ──────────────────────────────
                const Text(
                  'Terima kasih atas kunjungan Anda!',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '— Powered by Metal —',
                  style: TextStyle(fontSize: 9, color: Colors.black38),
                ),
              ],
            ),
          ),
            ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: () => Navigator.pop(context),
              //     icon: const Icon(Icons.arrow_back_rounded),
              //     label: const Text('Kembali'),
              //   ),
              // ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSharing ? null : _shareReceipt,
                  icon: _isSharing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.share_rounded),
                  label: const Text('Bagikan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BluetoothPrinterView(transaction: widget.transaction),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Cetak'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Capture receipt as image and share it
  Future<void> _shareReceipt() async {
    try {
      setState(() => _isSharing = true);
      
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil gambar struk')),
          );
        }
        return;
      }

      // Capture with higher pixel ratio for better quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Create a temporary file name
      final fileName = 'struk_${widget.transaction.id}.png';
      
      // Share the image
      await Share.shareXFiles(
        [XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName)],
        subject: 'Struk Pembayaran - ${widget.transaction.date.toString().split(' ')[0]}',
        text: 'Berikut adalah struk pembayaran Anda. Terima kasih!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Widget _buildPaymentMethodWidget() {
    if (widget.transaction.paymentMethod == 'Transfer' &&
        widget.transaction.transferBank != null) {
      final urlImage = _transferBank?.urlImage;
      final bankName = _transferBank?.namaBank ?? 'Transfer';
      final accountNumber = widget.transaction.transferAccountNumber ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (urlImage != null)
            Image.network(
              urlImage,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                bankName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            )
          else
            Text(
              bankName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          if (accountNumber.isNotEmpty)
            Text(
              accountNumber,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
        ],
      );
    }
    return Text(
      widget.transaction.paymentMethod,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _dashedDivider() {
    return Row(
      children: List.generate(
        40,
        (i) => Expanded(
          child: Container(
            height: 1,
            color: i.isEven ? Colors.grey.shade400 : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
