import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../models/printer_settings.dart';
import '../../services/thermal_printer_service.dart';
import '../../utils/theme.dart';

/// Printer & paper settings page — modern, user-friendly design.
class PrinterSettingsView extends StatefulWidget {
  const PrinterSettingsView({super.key});

  @override
  State<PrinterSettingsView> createState() => _PrinterSettingsViewState();
}

class _PrinterSettingsViewState extends State<PrinterSettingsView> {
  final ThermalPrinterService _printerService = ThermalPrinterService();
  PrinterSettings? _settings;
  bool _isLoading = true;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isSaving = false;
  List<BluetoothInfo> _devices = [];

  late TextEditingController _footerCtrl;
  late TextEditingController _footerSecondCtrl;

  @override
  void initState() {
    super.initState();
    _footerCtrl = TextEditingController();
    _footerSecondCtrl = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _footerCtrl.dispose();
    _footerSecondCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await PrinterSettings.load();
    if (mounted) {
      setState(() {
        _settings = s;
        _footerCtrl.text = s.footerText;
        _footerSecondCtrl.text = s.footerSecondLine;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _isSaving = true);
    _settings!.footerText = _footerCtrl.text.trim();
    _settings!.footerSecondLine = _footerSecondCtrl.text.trim();
    await _settings!.save();
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan printer berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset ke Default?'),
        content: const Text(
          'Semua pengaturan printer akan dikembalikan ke nilai awal. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final s = await PrinterSettings.resetToDefaults();
    if (mounted) {
      setState(() {
        _settings = s;
        _footerCtrl.text = s.footerText;
        _footerSecondCtrl.text = s.footerSecondLine;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan direset ke default')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Printer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final s = _settings!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Simpan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Hero Banner ──────────────────────────
          _heroBanner(),
          const SizedBox(height: 24),

          // ─── Printer Connection ───────────────────
          _sectionHeader(
            icon: Icons.bluetooth_rounded,
            title: 'Koneksi Printer',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _card(children: [
            // Saved printer info
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (_printerService.isConnected
                          ? AppTheme.accentColor
                          : Colors.grey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _printerService.isConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_disabled_rounded,
                  color: _printerService.isConnected
                      ? AppTheme.accentColor
                      : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                _printerService.isConnected
                    ? _printerService.connectedDeviceName ?? 'Terhubung'
                    : (s.savedPrinterName ?? 'Belum ada printer'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _printerService.isConnected
                    ? 'Terhubung — siap mencetak'
                    : (s.savedPrinterAddress != null
                        ? 'Tersimpan · Tap cari untuk menghubungkan'
                        : 'Tekan tombol di bawah untuk mencari printer'),
              ),
              trailing: _printerService.isConnected
                  ? IconButton(
                      icon: const Icon(Icons.link_off_rounded,
                          color: AppTheme.dangerColor),
                      onPressed: _disconnect,
                      tooltip: 'Putuskan',
                    )
                  : null,
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: (_isScanning || _isConnecting) ? null : _loadPairedDevices,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_rounded, size: 18),
                  label: Text(_isScanning ? 'Memuat...' : 'Perangkat Tersambung'),
                ),
              ),
            ),
            // Device list
            if (_devices.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_devices.length} perangkat ditemukan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ..._devices.map(_buildDeviceTile),
            ],
            if (s.savedPrinterName != null) ...[
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.autorenew_rounded, size: 20),
                title: const Text('Auto-Connect'),
                subtitle: const Text('Hubungkan otomatis saat cetak'),
                value: s.autoConnect,
                onChanged: (val) => setState(() => s.autoConnect = val),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.dangerColor, size: 20),
                title: const Text('Lupakan Printer',
                    style: TextStyle(color: AppTheme.dangerColor)),
                onTap: () {
                  setState(() {
                    s.savedPrinterName = null;
                    s.savedPrinterAddress = null;
                    s.autoConnect = false;
                  });
                },
              ),
            ],
          ]),

          const SizedBox(height: 24),

          // ─── Paper Size ───────────────────────────
          _sectionHeader(
            icon: Icons.description_rounded,
            title: 'Ukuran Kertas',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _card(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _paperSizeChip('57mm', s),
                  const SizedBox(width: 8),
                  _paperSizeChip('58mm', s),
                  const SizedBox(width: 8),
                  _paperSizeChip('80mm', s),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: AppTheme.infoColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.paperSize == '80mm'
                            ? 'Lebar cetak: 72mm (576 dots) — printer kasir besar'
                            : 'Lebar cetak: 48mm (384 dots) — printer portable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // ─── Margins ──────────────────────────────
          _sectionHeader(
            icon: Icons.space_bar_rounded,
            title: 'Margin Kertas',
            color: Colors.teal,
          ),
          const SizedBox(height: 8),
          _card(children: [
            _marginSlider('Atas', s.marginTop, (v) => setState(() => s.marginTop = v)),
            const Divider(height: 1),
            _marginSlider('Bawah', s.marginBottom, (v) => setState(() => s.marginBottom = v)),
            const Divider(height: 1),
            _marginSlider('Kiri', s.marginLeft, (v) => setState(() => s.marginLeft = v)),
            const Divider(height: 1),
            _marginSlider('Kanan', s.marginRight, (v) => setState(() => s.marginRight = v)),
          ]),

          const SizedBox(height: 24),

          // ─── Receipt Content ──────────────────────
          _sectionHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Konten Struk',
            color: Colors.purple,
          ),
          const SizedBox(height: 8),
          _card(children: [
            _toggleTile(Icons.image_rounded, 'Tampilkan Logo',
                'Logo toko di header struk', s.showLogo,
                (v) => setState(() => s.showLogo = v)),
            const Divider(height: 1),
            _toggleTile(Icons.location_on_rounded, 'Tampilkan Alamat',
                'Alamat toko di bawah nama', s.showAddress,
                (v) => setState(() => s.showAddress = v)),
            const Divider(height: 1),
            _toggleTile(Icons.phone_rounded, 'Tampilkan Telepon',
                'Nomor telepon toko', s.showPhone,
                (v) => setState(() => s.showPhone = v)),
            const Divider(height: 1),
            _toggleTile(Icons.notes_rounded, 'Tampilkan Deskripsi',
                'Deskripsi/slogan bisnis', s.showDescription,
                (v) => setState(() => s.showDescription = v)),
            const Divider(height: 1),
            _toggleTile(Icons.tag_rounded, 'ID Transaksi',
                'Nomor unik transaksi', s.showTransactionId,
                (v) => setState(() => s.showTransactionId = v)),
            const Divider(height: 1),
            _toggleTile(Icons.access_time_rounded, 'Tanggal & Waktu',
                'Waktu transaksi', s.showDateTime,
                (v) => setState(() => s.showDateTime = v)),
            const Divider(height: 1),
            _toggleTile(Icons.card_membership_rounded, 'Info Member',
                'Detail diskon member', s.showMemberInfo,
                (v) => setState(() => s.showMemberInfo = v)),
            const Divider(height: 1),
            _toggleTile(Icons.payment_rounded, 'Detail Pembayaran',
                'Jumlah bayar & kembalian', s.showPaymentDetails,
                (v) => setState(() => s.showPaymentDetails = v)),
          ]),

          const SizedBox(height: 24),

          // ─── Footer Customization ─────────────────
          _sectionHeader(
            icon: Icons.edit_note_rounded,
            title: 'Footer Struk',
            color: Colors.indigo,
          ),
          const SizedBox(height: 8),
          _card(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _footerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Baris Pertama',
                      hintText: 'Contoh: Terima kasih!',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _footerSecondCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Baris Kedua',
                      hintText: 'Contoh: — Powered by Metal —',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLength: 50,
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // ─── Print Behavior ───────────────────────
          _sectionHeader(
            icon: Icons.tune_rounded,
            title: 'Perilaku Cetak',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 8),
          _card(children: [
            // Font scale
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_size_rounded, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ukuran Font', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(_fontScaleLabel(s.fontScale), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 36,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('S', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 1, label: Text('M', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 2, label: Text('L', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {s.fontScale},
                      onSelectionChanged: (val) => setState(() => s.fontScale = val.first),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Feed lines
            ListTile(
              leading: const Icon(Icons.arrow_downward_rounded, size: 20),
              title: const Text('Baris Kosong Setelah Struk'),
              subtitle: Text('${s.feedLinesAfter} baris'),
              trailing: SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: s.feedLinesAfter > 0
                          ? () => setState(() => s.feedLinesAfter--)
                          : null,
                    ),
                    Text('${s.feedLinesAfter}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: s.feedLinesAfter < 10
                          ? () => setState(() => s.feedLinesAfter++)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _toggleTile(Icons.content_cut_rounded, 'Auto Cut',
                'Potong kertas otomatis setelah cetak', s.autoCut,
                (v) => setState(() => s.autoCut = v)),
            const Divider(height: 1),
            _toggleTile(Icons.copy_rounded, 'Cetak Rangkap',
                'Cetak 2 salinan otomatis', s.printDuplicate,
                (v) => setState(() => s.printDuplicate = v)),
          ]),

          const SizedBox(height: 24),

          // ─── Test Print ───────────────────────────
          _sectionHeader(
            icon: Icons.print_rounded,
            title: 'Uji Cetak',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _card(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_rounded,
                            size: 32, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Pastikan printer terhubung sebelum uji cetak',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _printerService.isConnected
                          ? _testPrint
                          : null,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Cetak Halaman Uji'),
                    ),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // ─── Reset ────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: _resetDefaults,
              icon: const Icon(Icons.restore_rounded,
                  size: 18, color: AppTheme.dangerColor),
              label: const Text('Reset ke Pengaturan Default',
                  style: TextStyle(color: AppTheme.dangerColor)),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────

  Widget _heroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.print_rounded,
                color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengaturan Printer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atur kertas, margin, konten struk, dan hubungkan printer thermal Anda.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppTheme.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _paperSizeChip(String size, PrinterSettings s) {
    final selected = s.paperSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          s.paperSize = size;
          s.paperWidthDots = PrinterSettings.dotsForPaperSize(size);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : Colors.grey.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_rounded,
                color: selected ? AppTheme.primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                size,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? AppTheme.primaryColor : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                size == '80mm' ? '576 dots' : '384 dots',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _marginSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 20,
              divisions: 20,
              label: '${value.toInt()} mm',
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${value.toInt()} mm',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, size: 20),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }

  Widget _buildDeviceTile(BluetoothInfo device) {
    final name = device.name.isNotEmpty ? device.name : 'Unknown';
    final isSaved = _settings?.savedPrinterAddress == device.macAdress;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.print_rounded,
            size: 18, color: AppTheme.primaryColor),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (isSaved) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Tersimpan',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      subtitle: Text(
        device.macAdress,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: SizedBox(
        width: 90,
        height: 32,
        child: ElevatedButton(
          onPressed: _isConnecting
              ? null
              : () => _connectDevice(device),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: _isConnecting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Hubungkan'),
        ),
      ),
    );
  }

  String _fontScaleLabel(int scale) {
    switch (scale) {
      case 0:
        return 'Kecil - hemat kertas';
      case 2:
        return 'Besar - mudah dibaca';
      default:
        return 'Normal - standar';
    }
  }

  // ─── Actions ──────────────────────────────────────

  Future<void> _loadPairedDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      final results = await _printerService.getPairedDevices();
      if (mounted) setState(() => _devices = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _connectDevice(BluetoothInfo device) async {
    setState(() => _isConnecting = true);

    try {
      await _printerService.connect(device);
      if (mounted) {
        setState(() {
          _settings!.savedPrinterName = device.name;
          _settings!.savedPrinterAddress = device.macAdress;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terhubung ke ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer terputus')),
      );
    }
  }

  Future<void> _testPrint() async {
    try {
      final profile = await CapabilityProfile.load();
      final paper = _settings!.paperSize == '80mm'
          ? PaperSize.mm80
          : PaperSize.mm58;
      final gen = Generator(paper, profile);
      List<int> bytes = [];

      bytes += gen.text('=== UJI CETAK ===',
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2));
      bytes += gen.feed(1);
      bytes += gen.text('Printer terhubung dengan baik!',
          styles: const PosStyles(align: PosAlign.center));
      bytes += gen.text('Kertas: ${_settings!.paperSize}',
          styles: const PosStyles(align: PosAlign.center));
      bytes += gen.text('Font: ${_fontScaleLabel(_settings!.fontScale)}',
          styles: const PosStyles(align: PosAlign.center));
      bytes += gen.hr();
      bytes += gen.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ',
          styles: const PosStyles(align: PosAlign.center));
      bytes += gen.text('abcdefghijklmnopqrstuvwxyz',
          styles: const PosStyles(align: PosAlign.center));
      bytes += gen.text('0123456789 !@#\$%^&*()',
          styles: const PosStyles(align: PosAlign.center));
      bytes += gen.hr();
      bytes += gen.text('Metal - LabaKu',
          styles: const PosStyles(align: PosAlign.center));
      bytes += gen.feed(_settings!.feedLinesAfter);
      if (_settings!.autoCut) bytes += gen.cut();

      // Write directly
      final ch = _printerService.isConnected ? true : false;
      if (!ch) throw Exception('Printer belum terhubung');

      // Use the service's internal write
      await _printerService.printRawBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Halaman uji berhasil dicetak!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal cetak: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }
}
