import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_version_service.dart';

/// Full-screen blocking page shown when:
/// - App version is below minimum required (force update)
/// - Server is in maintenance mode
///
/// The user cannot proceed without updating.
class ForceUpdateView extends StatelessWidget {
  final VersionCheckResult versionInfo;

  const ForceUpdateView({super.key, required this.versionInfo});

  bool get _isMaintenance => versionInfo.maintenanceMode;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Block back button
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isMaintenance
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(),

                  // ── Animated Icon ──────────────────────────
                  _AnimatedIcon(isMaintenance: _isMaintenance),

                  const SizedBox(height: 32),

                  // ── Title ─────────────────────────────────
                  Text(
                    _isMaintenance ? 'Sedang Pemeliharaan' : 'Pembaruan Diperlukan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Subtitle ──────────────────────────────
                  Text(
                    _isMaintenance
                        ? versionInfo.maintenanceMsg
                        : 'Versi aplikasi Anda sudah tidak didukung. Perbarui ke versi terbaru untuk terus menggunakan Metal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Version Info Card ─────────────────────
                  if (!_isMaintenance) ...[
                    _VersionInfoCard(versionInfo: versionInfo),
                    const SizedBox(height: 16),
                  ],

                  // ── Release Notes ─────────────────────────
                  if (!_isMaintenance && versionInfo.releaseNotes.isNotEmpty) ...[
                    _ReleaseNotesCard(
                      notes: versionInfo.releaseNotes,
                      version: versionInfo.latestVersion,
                    ),
                    const SizedBox(height: 32),
                  ] else
                    const SizedBox(height: 32),

                  const Spacer(),

                  // ── CTA Button ────────────────────────────
                  if (!_isMaintenance && versionInfo.updateUrl.isNotEmpty)
                    _UpdateButton(url: versionInfo.updateUrl),

                  if (_isMaintenance) _MaintenanceStatus(),

                  const SizedBox(height: 24),

                  // ── Footer ────────────────────────────────
                  Text(
                    _isMaintenance
                        ? 'Silakan coba lagi nanti'
                        : 'Versi Anda: ${versionInfo.currentVersion}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated Icon ─────────────────────────────────────────────────────────────

class _AnimatedIcon extends StatefulWidget {
  final bool isMaintenance;
  const _AnimatedIcon({required this.isMaintenance});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Icon(
          widget.isMaintenance
              ? Icons.construction_rounded
              : Icons.system_update_rounded,
          color: Colors.white,
          size: 56,
        ),
      ),
    );
  }
}

// ── Version Info Card ─────────────────────────────────────────────────────────

class _VersionInfoCard extends StatelessWidget {
  final VersionCheckResult versionInfo;
  const _VersionInfoCard({required this.versionInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VersionColumn(
              label: 'Versi Anda',
              value: versionInfo.currentVersion,
              isOutdated: true,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _VersionColumn(
              label: 'Versi Terbaru',
              value: versionInfo.latestVersion,
              isOutdated: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool isOutdated;

  const _VersionColumn({
    required this.label,
    required this.value,
    required this.isOutdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOutdated) ...[
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: isOutdated ? const Color(0xFFFBBF24) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Release Notes Card ────────────────────────────────────────────────────────

class _ReleaseNotesCard extends StatelessWidget {
  final String notes;
  final String version;
  const _ReleaseNotesCard({required this.notes, required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF93C5FD), size: 16),
              const SizedBox(width: 8),
              Text(
                'Yang Baru di v$version',
                style: const TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Update Button ─────────────────────────────────────────────────────────────

class _UpdateButton extends StatefulWidget {
  final String url;
  const _UpdateButton({required this.url});

  @override
  State<_UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<_UpdateButton> {
  bool _loading = false;

  Future<void> _openStore() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _openStore,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1D4ED8),
                ),
              )
            : const Icon(Icons.download_rounded, size: 22),
        label: Text(
          _loading ? 'Membuka...' : 'Perbarui Sekarang',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1D4ED8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Maintenance Status ────────────────────────────────────────────────────────

class _MaintenanceStatus extends StatefulWidget {
  @override
  State<_MaintenanceStatus> createState() => _MaintenanceStatusState();
}

class _MaintenanceStatusState extends State<_MaintenanceStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: _controller,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFBBF24),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Sistem sedang dalam pemeliharaan',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
