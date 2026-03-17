import 'dart:async';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../models/member.dart';
import '../../models/store_model.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../services/store_service.dart';
import '../../services/thermal_printer_service.dart';
import '../../utils/theme.dart';

/// Bluetooth thermal printer screen.
/// Shows paired devices, connects via Bluetooth Classic, and prints receipt.
class BluetoothPrinterView extends StatefulWidget {
  final SalesTransaction transaction;

  const BluetoothPrinterView({super.key, required this.transaction});

  @override
  State<BluetoothPrinterView> createState() => _BluetoothPrinterViewState();
}

class _BluetoothPrinterViewState extends State<BluetoothPrinterView> {
  final ThermalPrinterService _printerService = ThermalPrinterService();
  final StoreService _storeService = StoreService();

  bool _isLoading = false;
  bool _isPrinting = false;
  bool _isConnecting = false;
  String? _statusMessage;
  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _selectedDevice;
  StoreModel? _store;
  Member? _member;

  @override
  void initState() {
    super.initState();
    _loadStoreAndMember();
    _loadPairedDevices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadStoreAndMember() async {
    final result = await _storeService.getMyStores();
    if (result.stores.isNotEmpty && mounted) {
      setState(() => _store = result.stores.first);
    }
    if (widget.transaction.memberId != null) {
      final member = await DatabaseService()
          .getMemberById(widget.transaction.memberId!);
      if (mounted) setState(() => _member = member);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _printerService.isConnected;

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
              color: isConnected
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected
                    ? AppTheme.accentColor.withValues(alpha: 0.3)
                    : AppTheme.warningColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_rounded,
                  color: isConnected
                      ? AppTheme.accentColor
                      : AppTheme.warningColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage ??
                        (isConnected
                            ? 'Terhubung ke ${_printerService.connectedDeviceName}'
                            : 'Belum terhubung ke printer'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isConnected
                          ? AppTheme.accentColor
                          : AppTheme.warningColor,
                    ),
                  ),
                ),
                if (isConnected)
                  IconButton(
                    icon: const Icon(Icons.bluetooth_disabled_rounded,
                        color: AppTheme.dangerColor, size: 20),
                    tooltip: 'Putuskan',
                    onPressed: _disconnect,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Refresh paired devices ────────────────
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: (_isLoading || _isConnecting) ? null : _loadPairedDevices,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_isLoading ? 'Memuat...' : 'Muat Ulang Perangkat'),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Device list ───────────────────────────
          if (_devices.isNotEmpty) ...[
            const Text('Perangkat Tersambung (Paired):',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._devices.map((device) {
              final isSelected = _selectedDevice?.macAdress == device.macAdress;
              return ListTile(
                title: Text(device.name.isNotEmpty ? device.name : 'Unknown'),
                subtitle: Text(device.macAdress),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
                trailing: const Icon(Icons.print_rounded, size: 18, color: Colors.grey),
                onTap: () => setState(() => _selectedDevice = device),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // ─── Connect button ────────────────────────
          if (_selectedDevice != null && !isConnected)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connect,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bluetooth_connected_rounded),
                label: Text(_isConnecting ? 'Menghubungkan...' : 'Hubungkan'),
              ),
            ),

          // ─── Print button ─────────────────────────
          if (isConnected) ...[
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
                _instruction('2. Pair printer di Pengaturan Bluetooth HP'),
                _instruction('3. Pilih printer dari daftar di atas'),
                _instruction('4. Tekan "Hubungkan"'),
                _instruction('5. Tekan "Cetak Struk"'),
                const SizedBox(height: 8),
                Text(
                  'Mendukung printer thermal 57mm/58mm/80mm via Bluetooth Classic',
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

  /// Load paired Bluetooth devices.
  Future<void> _loadPairedDevices() async {
    setState(() {
      _isLoading = true;
      _devices = [];
      _selectedDevice = null;
      _statusMessage = 'Memuat perangkat...';
    });

    try {
      final results = await _printerService.getPairedDevices();
      if (mounted) {
        setState(() {
          _devices = results;
          _statusMessage = results.isEmpty
              ? 'Tidak ada perangkat yang dipasangkan. Pair printer di Pengaturan Bluetooth.'
              : '${results.length} perangkat ditemukan';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Connect to the selected printer.
  Future<void> _connect() async {
    if (_selectedDevice == null) return;
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Menghubungkan...';
    });

    try {
      await _printerService.connect(_selectedDevice!);
      if (mounted) {
        setState(() {
          _statusMessage =
              'Terhubung ke ${_printerService.connectedDeviceName}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Gagal menghubungkan: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  /// Disconnect from the printer.
  Future<void> _disconnect() async {
    await _printerService.disconnect();
    if (mounted) {
      setState(() {
        _statusMessage = 'Printer terputus';
        _selectedDevice = null;
      });
    }
  }

  /// Print the receipt via Bluetooth thermal printer.
  Future<void> _printReceipt() async {
    if (_store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data toko belum dimuat')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
      _statusMessage = 'Mencetak struk...';
    });

    try {
      await _printerService.printReceipt(
        transaction: widget.transaction,
        store: _store!,
        memberName: _member?.name,
      );

      if (mounted) {
        setState(() => _statusMessage = 'Struk berhasil dicetak!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil dicetak!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Gagal mencetak: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}
