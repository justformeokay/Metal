import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/expense_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/store_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../services/backup_service.dart';
import '../../services/cloud_backup_service.dart';
import '../../services/store_service.dart';
import '../about/about_view.dart';

/// Settings screen — business profile, theme, backup/restore.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final StoreService _storeService = StoreService();
  final ImagePicker _imagePicker = ImagePicker();
  StoreModel? _userStore;
  String? _logoPath;
  bool _isLoading = true;
  bool _isUploadingLogo = false;
  bool _isCloudSyncing = false;
  bool _autoBackupEnabled = true;
  DateTime? _lastCloudBackup;
  double _lastBackupSizeMB = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserStore();
    _loadCloudBackupState();
  }

  Future<void> _loadCloudBackupState() async {
    final enabled = await CloudBackupService.isAutoBackupEnabled();
    final lastDate = await CloudBackupService.getLastBackupDate();
    final sizeMB = await CloudBackupService.getLastBackupSizeMB();
    if (mounted) {
      setState(() {
        _autoBackupEnabled = enabled;
        _lastCloudBackup = lastDate;
        _lastBackupSizeMB = sizeMB;
      });
    }
  }

  Future<void> _loadUserStore() async {
    final result = await _storeService.getMyStores();
    if (result.stores.isNotEmpty && mounted) {
      setState(() {
        _userStore = result.stores.first; // Get first store
        _logoPath = _userStore?.logoUrl; // Use server logo URL if available
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogoImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null && _userStore != null) {
      setState(() => _isUploadingLogo = true);
      
      final result = await _storeService.uploadStoreLogo(
        logoFile: File(pickedFile.path),
        storeName: _userStore!.storeName,
      );

      if (mounted) {
        setState(() => _isUploadingLogo = false);
        
        if (result.success && result.url != null) {
          setState(() {
            _logoPath = result.url;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo berhasil diupload ke server')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload logo: ${result.message}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final ctrl = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Center(
        child: SizedBox(
          width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.5),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          // ─── Business Profile ──────────────────────
          _sectionTitle('Profil Pengguna & Bisnis'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: const Text('Nama Pengguna'),
                subtitle: Text(authCtrl.user?.name ?? 'Belum diisi'),
                trailing: const Icon(Icons.info_outline),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.store_rounded),
                title: const Text('Nama Toko'),
                subtitle: Text(_isLoading
                    ? 'Memuat...'
                    : (_userStore?.storeName ?? 'Belum diisi')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isLoading ? null : () => _editProfile(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_rounded),
                title: const Text('Alamat'),
                subtitle: Text(_isLoading
                    ? 'Memuat...'
                    : (_userStore?.address?.isEmpty ?? true
                        ? 'Belum diisi'
                        : _userStore!.address!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isLoading ? null : () => _editProfile(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone_rounded),
                title: const Text('Telepon'),
                subtitle: Text(_isLoading
                    ? 'Memuat...'
                    : (_userStore?.phone?.isEmpty ?? true
                        ? 'Belum diisi'
                        : _userStore!.phone!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isLoading ? null : () => _editProfile(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: const Text('Deskripsi Bisnis'),
                subtitle: Text(_isLoading
                    ? 'Memuat...'
                    : (_userStore?.description?.isEmpty ?? true
                        ? 'Belum diisi'
                        : _userStore!.description!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isLoading ? null : () => _editProfile(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _isUploadingLogo
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_rounded),
                title: const Text('Logo Usaha'),
                subtitle: _isUploadingLogo
                    ? const Text('Mengunggah...')
                    : (_logoPath != null
                        ? (_logoPath!.startsWith('http')
                            ? const Text('Logo tersimpan di server')
                            : const Text('Logo tersimpan (lokal)')
                        )
                        : const Text('Belum ada logo')),
                trailing: const Icon(Icons.chevron_right),
                onTap: (_isLoading || _isUploadingLogo) ? null : _pickLogoImage,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Appearance ────────────────────────────
          _sectionTitle('Tampilan'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_rounded),
                title: const Text('Mode Gelap'),
                value: ctrl.isDarkMode,
                onChanged: (_) => ctrl.toggleThemeMode(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Cloud Backup ──────────────────────────
          _sectionTitle('Cloud Backup'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              ListTile(
                leading: _isCloudSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                title: const Text('Backup ke Server'),
                subtitle: Text(_lastCloudBackup != null
                    ? 'Terakhir: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_lastCloudBackup!)}'
                      '${_lastBackupSizeMB > 0 ? ' · ${_lastBackupSizeMB.toStringAsFixed(2)} MB' : ''}'
                    : 'Belum pernah backup'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isCloudSyncing ? null : () => _cloudBackup(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cloud_download_rounded),
                title: const Text('Restore dari Server'),
                subtitle: const Text('Pulihkan data dari backup server'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isCloudSyncing ? null : () => _cloudRestore(context),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.autorenew_rounded),
                title: const Text('Auto Backup Mingguan'),
                subtitle: const Text('Backup otomatis setiap 7 hari'),
                value: _autoBackupEnabled,
                onChanged: (val) async {
                  await CloudBackupService.setAutoBackupEnabled(val);
                  setState(() => _autoBackupEnabled = val);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Local Backup  ─────────────────────────
          _sectionTitle('Backup Lokal'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.save_rounded),
                title: const Text('Backup ke File'),
                subtitle: const Text('Simpan data ke file JSON lokal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _backup(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.folder_open_rounded),
                title: const Text('Restore dari File'),
                subtitle: const Text('Pulihkan dari file JSON lokal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _restore(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── About ─────────────────────────────────
          _sectionTitle('Tentang'),
          const SizedBox(height: 8),
          _settingsCard(
            children: [
              ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset('assets/final.png', height: 25),
                  ],
                ),
                subtitle: Text('Versi 1.0.0 · Kelola Bisnis Lebih Mudah'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutView()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Logout ────────────────────────────────
          _settingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppTheme.dangerColor),
                title: const Text(
                  'Keluar',
                  style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Logout dari akun Anda'),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ));
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppTheme.border,
        ),
      ),
      child: Column(children: children),
    );
  }

  /// Edit business profile dialog.
  void _editProfile(BuildContext context) {
    if (_userStore == null) return;

    final nameCtrl = TextEditingController(text: _userStore?.storeName ?? '');
    final addressCtrl =
        TextEditingController(text: _userStore?.address ?? '');
    final phoneCtrl = TextEditingController(text: _userStore?.phone ?? '');
    final descriptionCtrl =
        TextEditingController(text: _userStore?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil Toko'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Toko'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telepon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Bisnis',
                  hintText: 'Contoh: Toko pakaian berkualitas tinggi',
                ),
                maxLines: 2,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_userStore != null) {
                final result = await _storeService.updateStore(
                  storeId: _userStore!.id,
                  storeName: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  description: descriptionCtrl.text.trim(),
                );

                if (mounted) {
                  if (result.success && result.store != null) {
                    setState(() => _userStore = result.store);
                    if (mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Profil toko berhasil diperbarui'),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(result.message)),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _backup(BuildContext context) async {
    try {
      await BackupService.exportBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup berhasil disimpan')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal backup: $e')),
        );
      }
    }
  }

  Future<void> _cloudBackup(BuildContext context) async {
    setState(() => _isCloudSyncing = true);

    final result = await CloudBackupService.uploadBackup(backupType: 'manual');

    if (mounted) {
      setState(() => _isCloudSyncing = false);
      if (result.success) {
        await _loadCloudBackupState(); // Reload size + timestamp
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _cloudRestore(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore dari Server'),
        content: const Text(
          'Semua data lokal akan diganti dengan data dari backup server terakhir. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCloudSyncing = true);

    final result = await CloudBackupService.downloadAndRestore();

    if (mounted) {
      setState(() => _isCloudSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _restore(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'Semua data saat ini akan diganti dengan data dari file backup. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await BackupService.importBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal restore: $e')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Clear all cached controller data before logout
    context.read<ProductController>().clearData();
    context.read<TransactionController>().clearData();
    context.read<ExpenseController>().clearData();
    
    await context.read<AuthController>().logout();
    
    if (context.mounted) {
      // Pop back to home (AuthGate will show LoginScreen since isLoggedIn = false)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
