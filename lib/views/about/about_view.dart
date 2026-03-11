import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

/// About page — developer info and app technologies.
class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ─── App Info ────────────────────────────
            Center(
              child: Column(
                children: [
                  Image.asset('assets/final.png', height: 60),
                  const SizedBox(height: 12),
                  const Text(
                    'Kelola Bisnis Lebih Mudah',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Versi 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── Developer Info ──────────────────────
            _sectionTitle('Developer'),
            const SizedBox(height: 12),
            _infoCard(
              context,
              icon: Icons.person_rounded,
              title: 'Putra Budianto',
              subtitle: 'Creator & Developer',
            ),

            const SizedBox(height: 16),
            _contactButton(
              context,
              icon: Icons.phone_rounded,
              label: 'WhatsApp',
              value: '62881036480285',
              onTap: () => _launchWhatsApp('62881036480285'),
            ),
            const SizedBox(height: 8),
            _contactButton(
              context,
              icon: Icons.email_rounded,
              label: 'Email',
              value: 'info@karyadeveloperindonesia.com',
              onTap: () => _launchEmail('info@karyadeveloperindonesia.com'),
            ),
            const SizedBox(height: 8),
            _contactButton(
              context,
              icon: Icons.language_rounded,
              label: 'Website',
              value: 'karyadeveloperindonesia.com',
              onTap: () => _launchWebsite('https://karyadeveloperindonesia.com'),
            ),

            const SizedBox(height: 24),

            // ─── Services ────────────────────────────
            _sectionTitle('Layanan'),
            const SizedBox(height: 12),
            _serviceCard(context, 'Mobile App Development', 'Aplikasi custom untuk iOS & Android'),
            const SizedBox(height: 8),
            _serviceCard(context, 'Web App Development', 'Website responsif dan modern'),
            const SizedBox(height: 8),
            _serviceCard(context, 'App Maintenance', 'Support dan update berkelanjutan'),

            const SizedBox(height: 24),

            // ─── Technologies ────────────────────────
            _sectionTitle('Teknologi yang Digunakan'),
            const SizedBox(height: 12),
            _techCard(
              context,
              title: 'Frontend',
              technologies: [
                'Flutter 3.11.1',
                'Dart 3.x',
                'Material Design 3',
                'Provider (State Management)',
              ],
            ),
            const SizedBox(height: 12),
            _techCard(
              context,
              title: 'Backend',
              technologies: [
                'PHP 8.0+',
                'MySQL Database',
                'PDO MySQL Prepared Statements',
                'JWT Authentication (HMAC-SHA256)',
              ],
            ),
            const SizedBox(height: 12),
            _techCard(
              context,
              title: 'Local Storage',
              technologies: [
                'SQLite (sqflite)',
                'SharedPreferences',
                'File System (JSON Backup)',
              ],
            ),
            const SizedBox(height: 12),
            _techCard(
              context,
              title: 'Libraries & Packages',
              technologies: [
                'http • intl • uuid',
                'fl_chart • pdf • printing',
                'path_provider • share_plus • file_picker',
                'image_picker • permission_handler',
                'mobile_scanner • barcode_widget • gal',
                'url_launcher • bank_service',
              ],
            ),

            const SizedBox(height: 24),

            // ─── Features ─────────────────────────────
            _sectionTitle('Fitur Utama'),
            const SizedBox(height: 12),
            _featureItem('✓ Manajemen Produk', 'Kelola stok barang dengan mudah'),
            const SizedBox(height: 8),
            _featureItem('✓ Barcode & QR Code', 'Generate, scan & download barcode produk'),
            const SizedBox(height: 8),
            _featureItem('✓ Penjualan & Checkout', 'Proses transaksi cepat dengan printer'),
            const SizedBox(height: 8),
            _featureItem('✓ Metode Pembayaran', '6 metode: Tunai, QRIS, Gopay, OVO, Dana, Transfer'),
            const SizedBox(height: 8),
            _featureItem('✓ Transfer Bank', 'Pilih bank & input nomor rekening pengirim'),
            const SizedBox(height: 8),
            _featureItem('✓ Bagikan Struk', 'Screenshot & share struk via WhatsApp, Email, dll'),
            const SizedBox(height: 8),
            _featureItem('✓ Detail Transaksi', 'Modal untuk lihat detail produk & pembayaran'),
            const SizedBox(height: 8),
            _featureItem('✓ Laporan Keuangan', 'Analisis grafik dan export PDF'),
            const SizedBox(height: 8),
            _featureItem('✓ Kelola Pengeluaran', 'Track biaya operasional bisnis'),
            const SizedBox(height: 8),
            _featureItem('✓ Peringatan Inventory', 'Kartu modern untuk stok minim'),
            const SizedBox(height: 8),
            _featureItem('✓ Cloud Backup', 'Sinkronisasi otomatis ke server'),
            const SizedBox(height: 8),
            _featureItem('✓ Kalkulator Standar', 'Kalkulator iOS-style dengan swipe-delete'),
            const SizedBox(height: 8),
            _featureItem('✓ Kalkulator Keuangan', 'Kembalian, diskon, margin, pajak & markup'),
            const SizedBox(height: 8),
            _featureItem('✓ Offline Mode', 'Aplikasi jalan tanpa internet'),

            const SizedBox(height: 32),

            // ─── Footer ───────────────────────────────
            Center(
              child: Column(
                children: [
                  const Text(
                    '© 2026 Karya Developer Indonesia',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All rights reserved',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.border.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        subtitle: Text(value, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _serviceCard(BuildContext context, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.border.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _techCard(
    BuildContext context, {
    required String title,
    required List<String> technologies,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.border.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...technologies.map((tech) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const SizedBox(width: 4),
                const Text('•',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    )),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tech,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _featureItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka WhatsApp';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters(<String, String>{
        'subject': 'LabaKu - Pertanyaan / Inquiry',
      }),
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Tidak dapat membuka email';
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri websiteUrl = Uri.parse(url);
    try {
      if (await canLaunchUrl(websiteUrl)) {
        await launchUrl(websiteUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try to launch with webViewController
        await launchUrl(websiteUrl);
      }
    } catch (e) {
      debugPrint('Error launching website: $e');
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
