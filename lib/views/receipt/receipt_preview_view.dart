import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../models/transaction.dart';
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
  StoreModel? _userStore;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStore();
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
    final storeTagline = _userStore?.storeName != null ? 'Terima kasih atas kunjungan Anda!' : null;

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
                        ],
                      ),
                    )),

                const SizedBox(height: 8),
                _dashedDivider(),
                const SizedBox(height: 8),

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
                const SizedBox(height: 16),

                // ─── Footer ──────────────────────────────
                Text(
                  storeTagline ?? 'Terima kasih atas kunjungan Anda!',
                  style: const TextStyle(
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
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
                  label: const Text('Cetak Struk'),
                ),
              ),
            ],
          ),
        ),
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
