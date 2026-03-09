import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

/// Result of a version check against the server.
class VersionCheckResult {
  final bool isSupported;       // false → must update
  final bool maintenanceMode;   // true  → server is down for maintenance
  final String currentVersion;  // installed version
  final String latestVersion;   // server latest
  final String minVersion;      // server minimum allowed
  final String updateUrl;       // download URL
  final String releaseNotes;    // changelog
  final String maintenanceMsg;  // message when in maintenance

  const VersionCheckResult({
    required this.isSupported,
    required this.maintenanceMode,
    required this.currentVersion,
    required this.latestVersion,
    required this.minVersion,
    required this.updateUrl,
    required this.releaseNotes,
    required this.maintenanceMsg,
  });

  bool get hasUpdate => _compareVersions(currentVersion, latestVersion) < 0;
}

/// Check the app version against the server-configured minimum.
class AppVersionService {
  /// Fetch version info from server and compare with installed version.
  /// Returns `null` if the check fails (no internet, etc.) — treat as ok.
  static Future<VersionCheckResult?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "1.0.0"

      final response = await ApiService.get('/app/version', withAuth: false);
      if (response['success'] != true || response['data'] == null) return null;

      final data = response['data'] as Map<String, dynamic>;

      final latestVersion  = (data['latest_version']   as String?) ?? currentVersion;
      final minVersion     = (data['min_version']      as String?) ?? '1.0.0';
      final forceUpdate    = data['force_update']      as bool?    ?? false;
      final updateUrl      = (data['update_url']       as String?) ?? '';
      final releaseNotes   = (data['release_notes']    as String?) ?? '';
      final maintenance    = data['maintenance_mode']  as bool?    ?? false;
      final maintenanceMsg = (data['maintenance_msg']  as String?) ?? 'Sedang dalam pemeliharaan.';

      // When force_update is true, block any version below latest_version.
      // This means: set latestVersion = '1.1.0' + forceUpdate = true
      // → anyone on '1.0.0' gets blocked automatically.
      final isSupported = !forceUpdate ||
          _compareVersions(currentVersion, latestVersion) >= 0;

      return VersionCheckResult(
        isSupported: isSupported,
        maintenanceMode: maintenance,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        minVersion: minVersion,
        updateUrl: updateUrl,
        releaseNotes: releaseNotes,
        maintenanceMsg: maintenanceMsg,
      );
    } catch (e) {
      print('⚠️ Version check failed (non-critical): $e');
      return null; // Don't block user if check errors out
    }
  }
}

/// Compare two semver strings (major.minor.patch).
/// Returns negative if a < b, 0 if equal, positive if a > b.
int _compareVersions(String a, String b) {
  final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

  for (int i = 0; i < 3; i++) {
    final av = i < aParts.length ? aParts[i] : 0;
    final bv = i < bParts.length ? bParts[i] : 0;
    if (av != bv) return av - bv;
  }
  return 0;
}
