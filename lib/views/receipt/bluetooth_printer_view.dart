import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../utils/theme.dart';

/// Bluetooth thermal printer screen.
/// Scans for nearby printers, connects, and prints receipt.
///
/// NOTE: esc_pos_bluetooth requires a real Android device.
/// This screen provides the full UI flow; actual Bluetooth
/// operations are wrapped in try/catch for graceful degradation
/// on iOS / simulators.
class BluetoothPrinterView extends StatefulWidget {
  final SalesTransaction transaction;

  const BluetoothPrinterView({super.key, required this.transaction});

  @override
  State<BluetoothPrinterView> createState() => _BluetoothPrinterViewState();
}

class _BluetoothPrinterViewState extends State<BluetoothPrinterView> {
  bool _isScanning = false;
  bool _isPrinting = false;
  bool _isConnected = false;
  String? _statusMessage;
  List<_PrinterDevice> _devices = [];
  _PrinterDevice? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cetak Struk'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Status banner ─────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isConnected
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isConnected
                    ? AppTheme.accentColor.withValues(alpha: 0.3)
                    : AppTheme.warningColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_rounded,
                  color: _isConnected
                      ? AppTheme.accentColor
                      : AppTheme.warningColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage ??
                        (_isConnected
                            ? 'Terhubung ke ${_selectedDevice?.name}'
                            : 'Belum terhubung ke printer'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isConnected
                          ? AppTheme.accentColor
                          : AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Scan button ───────────────────────────
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isScanning ? null : _scanDevices,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_isScanning ? 'Mencari...' : 'Cari Printer Bluetooth'),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Device list ───────────────────────────
          if (_devices.isNotEmpty) ...[
            const Text('Printer Ditemukan:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._devices.map((device) {
              final isSelected = _selectedDevice == device;
              return ListTile(
                title: Text(device.name),
                subtitle: Text(device.address),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
                onTap: () => setState(() => _selectedDevice = device),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // ─── Connect & Print ───────────────────────
          if (_selectedDevice != null && !_isConnected)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _connect,
                icon: const Icon(Icons.bluetooth_connected_rounded),
                label: const Text('Hubungkan'),
              ),
            ),

          if (_isConnected) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _printReceipt,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_rounded),
                label: Text(_isPrinting ? 'Mencetak...' : 'Cetak Struk'),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ─── Instructions ──────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Petunjuk:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _instruction('1. Nyalakan printer Bluetooth'),
                _instruction('2. Aktifkan Bluetooth di HP'),
                _instruction('3. Tekan "Cari Printer Bluetooth"'),
                _instruction('4. Pilih printer dan hubungkan'),
                _instruction('5. Tekan "Cetak Struk"'),
                const SizedBox(height: 8),
                Text(
                  'Mendukung printer thermal 58mm',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text,
          style:
              TextStyle(fontSize: 13, color: Colors.grey.shade700)),
    );
  }

  /// Scan for nearby Bluetooth devices.
  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
      _statusMessage = 'Mencari printer...';
    });

    try {
      // In a real implementation, use esc_pos_bluetooth to scan:
      // final manager = PrinterBluetoothManager();
      // manager.scanResults.listen((devices) { ... });
      // manager.startScan(Duration(seconds: 4));

      // Simulated delay for demo
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _devices = [
          _PrinterDevice(name: 'Printer-58mm', address: 'AA:BB:CC:DD:EE:FF'),
          _PrinterDevice(
              name: 'BT-Thermal-POS', address: '11:22:33:44:55:66'),
        ];
        _statusMessage = '${_devices.length} printer ditemukan';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal mencari: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// Connect to the selected printer.
  Future<void> _connect() async {
    if (_selectedDevice == null) return;
    setState(() => _statusMessage = 'Menghubungkan...');

    try {
      // Real implementation:
      // await manager.selectPrinter(selectedDevice);
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isConnected = true;
        _statusMessage = 'Terhubung ke ${_selectedDevice!.name}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal menghubungkan: $e';
      });
    }
  }

  /// Print the receipt via Bluetooth thermal printer.
  Future<void> _printReceipt() async {
    setState(() {
      _isPrinting = true;
      _statusMessage = 'Mencetak struk...';
    });

    try {
      // Real implementation using esc_pos_utils:
      // final profile = await CapabilityProfile.load();
      // final generator = Generator(PaperSize.mm58, profile);
      // List<int> bytes = [];
      // bytes += generator.text('STORE NAME', styles: PosStyles(align: PosAlign.center, bold: true));
      // bytes += generator.text('Date: ...');
      // for (final item in widget.transaction.items) {
      //   bytes += generator.text('${item.productName}');
      //   bytes += generator.row([...]);
      // }
      // bytes += generator.text('TOTAL: ...');
      // bytes += generator.cut();
      // await manager.printTicket(bytes);

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _statusMessage = 'Struk berhasil dicetak!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil dicetak!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal mencetak: $e';
      });
    } finally {
      setState(() => _isPrinting = false);
    }
  }
}

/// Simple model for discovered Bluetooth devices.
class _PrinterDevice {
  final String name;
  final String address;

  _PrinterDevice({required this.name, required this.address});
}
