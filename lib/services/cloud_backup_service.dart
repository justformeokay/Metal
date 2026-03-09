import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'store_service.dart';

/// Cloud backup service — upload/download backups to/from server.
///
/// Strategy: Offline-first with periodic sync.
/// - Data is always stored locally in SQLite (fast, no internet needed).
/// - Backups are uploaded to the server on demand or automatically.
/// - User can restore from the latest server backup on any device.
class CloudBackupService {
  static final DatabaseService _db = DatabaseService();
  static final StoreService _storeService = StoreService();

  static const String _lastBackupKey = 'last_cloud_backup';
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _lastBackupSizeKey = 'last_cloud_backup_size';
  static const int autoBackupIntervalDays = 3;

  // ─── Upload Backup ────────────────────────────────────────────────

  /// Upload current local data to the server.
  /// Returns (success, message).
  static Future<({bool success, String message})> uploadBackup({
    String backupType = 'manual',
  }) async {
    try {
      // 1. Get user's store ID
      final storeId = await _getStoreId();
      if (storeId == null) {
        return (success: false, message: 'Toko belum ditemukan. Silakan buat toko terlebih dahulu.');
      }

      // 2. Export local data
      final backupData = await _db.exportAllData();

      // Track backup size before uploading
      final backupJson = backupData.toString();
      final sizeBytes = backupJson.length;
      final sizeKB = sizeBytes / 1024;
      final sizeMB = sizeKB / 1024;
      print('📦 Backup size: ${sizeMB.toStringAsFixed(2)} MB (${sizeKB.toStringAsFixed(0)} KB)');

      // 3. Get device name
      final deviceName = Platform.isAndroid
          ? 'Android'
          : Platform.isIOS
              ? 'iOS'
              : 'Unknown';

      // 4. Upload to server — track duration
      final uploadStart = DateTime.now();
      final response = await ApiService.post(
        '/backup/upload',
        body: {
          'store_id': storeId,
          'backup_data': backupData,
          'device_name': deviceName,
          'backup_type': backupType,
        },
      );
      final uploadDuration = DateTime.now().difference(uploadStart);
      print('⏱️ Upload took: ${uploadDuration.inSeconds}s');

      if (response['success'] == true) {
        // Save last backup timestamp + size
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
        await prefs.setDouble(_lastBackupSizeKey, sizeMB);

        return (success: true, message: 'Backup berhasil diupload ke server');
      }

      return (success: false, message: (response['message'] ?? 'Gagal upload backup').toString());
    } catch (e) {
      return (success: false, message: 'Gagal upload: $e');
    }
  }

  // ─── Download & Restore ───────────────────────────────────────────

  /// Download the latest backup from the server and restore it locally.
  /// Returns (success, message).
  static Future<({bool success, String message})> downloadAndRestore() async {
    try {
      // 1. Get user's store ID
      final storeId = await _getStoreId();
      if (storeId == null) {
        return (success: false, message: 'Toko belum ditemukan.');
      }

      // 2. Fetch latest backup from server
      final response = await ApiService.get(
        '/backup/latest',
        queryParams: {'store_id': storeId.toString()},
      );

      if (response['success'] != true || response['data'] == null) {
        return (
          success: false,
          message: (response['message'] ?? 'Tidak ada backup ditemukan di server').toString(),
        );
      }

      final backupData = response['data']['backup_data'] as Map<String, dynamic>?;
      if (backupData == null) {
        return (success: false, message: 'Data backup kosong');
      }

      // 3. Import to local database
      await _db.importAllData(backupData);

      return (success: true, message: 'Data berhasil dipulihkan dari server');
    } catch (e) {
      return (success: false, message: 'Gagal restore: $e');
    }
  }

  // ─── Backup History ───────────────────────────────────────────────

  /// Get list of backups on the server (without data payload).
  static Future<({bool success, String message, List<Map<String, dynamic>> backups})>
      getBackupHistory() async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) {
        return (success: false, message: 'Toko belum ditemukan.', backups: <Map<String, dynamic>>[]);
      }

      final response = await ApiService.get(
        '/backup/history',
        queryParams: {'store_id': storeId.toString()},
      );

      if (response['success'] == true && response['data'] != null) {
        final data = (response['data'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return (success: true, message: 'OK', backups: data);
      }

      return (success: true, message: 'OK', backups: <Map<String, dynamic>>[]);
    } catch (e) {
      return (success: false, message: 'Gagal memuat history: $e', backups: <Map<String, dynamic>>[]);
    }
  }

  // ─── Auto Backup ─────────────────────────────────────────────────

  /// Check if auto-backup should run (every 7 days).
  /// Call this on app startup — will upload silently in background.
  static Future<void> checkAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoBackupKey) ?? true;
    if (!enabled) return;

    final lastBackupStr = prefs.getString(_lastBackupKey);
    if (lastBackupStr != null) {
      final lastBackup = DateTime.tryParse(lastBackupStr);
      if (lastBackup != null) {
        final daysSince = DateTime.now().difference(lastBackup).inDays;
        if (daysSince < autoBackupIntervalDays) {
          return; // Not time yet
        }
      }
    }

    // Time to auto-backup
    await uploadBackup(backupType: 'auto');
  }

  /// Get/set auto-backup preference.
  static Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? true;
  }

  static Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  /// Get last backup date.
  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastBackupKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// Get last backup size in MB (0.0 if unknown).
  static Future<double> getLastBackupSizeMB() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastBackupSizeKey) ?? 0.0;
  }

  // ─── Backup Availability Check ────────────────────────────────────

  /// Check if there is a backup on the server.
  /// Returns backup info (date, size) or null if no backup exists.
  /// Used to recommend restore after reinstall.
  static Future<Map<String, dynamic>?> checkServerBackupAvailable() async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) return null;

      final response = await ApiService.get(
        '/backup/history',
        queryParams: {'store_id': storeId.toString(), 'limit': '1'},
      );

      if (response['success'] == true && response['data'] != null) {
        final backups = response['data'] as List<dynamic>;
        if (backups.isNotEmpty) {
          return Map<String, dynamic>.from(backups.first as Map);
        }
      }
      return null;
    } catch (e) {
      print('\u274c Backup check error: $e');
      return null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  /// Get the user's first store ID from the API.
  static Future<int?> _getStoreId() async {
    final result = await _storeService.getMyStores();
    if (result.stores.isNotEmpty) {
      return result.stores.first.id;
    }
    return null;
  }
}
