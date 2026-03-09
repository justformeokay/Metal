<?php
/**
 * App Controller
 *
 * Manages app version configuration and force-update enforcement.
 *
 * Endpoints:
 *   GET /api/app/version  — Public. Returns minimum required version and
 *                           download URL so the client can enforce updates.
 */

require_once __DIR__ . '/../utils/Response.php';

class AppController
{
    /**
     * GET /api/app/version
     *
     * Returns the current app version metadata.
     * No authentication required — called before login screens too.
     *
     * Response data:
     *   - latest_version    string  Newest published version (e.g. "1.2.0")
     *   - min_version       string  Minimum version allowed to run (e.g. "1.1.0")
     *   - force_update      bool    True if versions below min_version must update
     *   - update_url        string  URL to download the new APK / Store page
     *   - release_notes     string  Short changelog for the latest version
     *   - maintenance_mode  bool    If true, app is fully disabled (server downtime)
     *   - maintenance_msg   string  Message shown during maintenance
     */
    public function version(): void
    {
        // ─── Configuration ────────────────────────────────────────────
        // Edit these values when you publish a new release.
        // ──────────────────────────────────────────────────────────────

        $latestVersion   = '1.0.0';
        $minVersion      = '1.0.0';   // Versions below this are force-blocked
        $forceUpdate     = false;       // Set to true to require update
        $updateUrl       = '';          // e.g. https://play.google.com/store/apps/...
        $releaseNotes    = 'Versi pertama LabaKu — manajemen toko UMKM serba bisa.';
        $maintenanceMode = false;
        $maintenanceMsg  = 'Sistem sedang dalam pemeliharaan. Mohon coba beberapa saat lagi.';

        Response::success('App version info retrieved', [
            'latest_version'   => $latestVersion,
            'min_version'      => $minVersion,
            'force_update'     => $forceUpdate,
            'update_url'       => $updateUrl,
            'release_notes'    => $releaseNotes,
            'maintenance_mode' => $maintenanceMode,
            'maintenance_msg'  => $maintenanceMsg,
        ]);
    }
}
