import 'package:shared_preferences/shared_preferences.dart';

/// Holds all printer & paper configuration settings.
/// Persisted via SharedPreferences.
class PrinterSettings {
  // Paper
  String paperSize; // '57mm', '58mm', '80mm'
  int paperWidthDots; // calculated from paperSize
  double marginLeft;
  double marginRight;
  double marginTop;
  double marginBottom;

  // Receipt content
  bool showLogo;
  bool showAddress;
  bool showPhone;
  bool showDescription;
  bool showTransactionId;
  bool showDateTime;
  bool showMemberInfo;
  bool showPaymentDetails;
  String footerText;
  String footerSecondLine;

  // Print behavior
  int feedLinesAfter; // blank lines before cut
  bool autoCut;
  bool printDuplicate;
  int fontScale; // 0 = small, 1 = normal, 2 = large

  // Saved printer
  String? savedPrinterName;
  String? savedPrinterAddress;
  bool autoConnect;

  PrinterSettings({
    this.paperSize = '57mm',
    this.paperWidthDots = 384,
    this.marginLeft = 0,
    this.marginRight = 0,
    this.marginTop = 0,
    this.marginBottom = 0,
    this.showLogo = false,
    this.showAddress = true,
    this.showPhone = true,
    this.showDescription = true,
    this.showTransactionId = true,
    this.showDateTime = true,
    this.showMemberInfo = true,
    this.showPaymentDetails = true,
    this.footerText = 'Terima kasih atas kunjungan Anda!',
    this.footerSecondLine = '— Powered by Metal —',
    this.feedLinesAfter = 2,
    this.autoCut = true,
    this.printDuplicate = false,
    this.fontScale = 1,
    this.savedPrinterName,
    this.savedPrinterAddress,
    this.autoConnect = false,
  });

  /// Paper size label → dot width mapping.
  static int dotsForPaperSize(String size) {
    switch (size) {
      case '57mm':
        return 384;
      case '58mm':
        return 384;
      case '80mm':
        return 576;
      default:
        return 384;
    }
  }

  /// Load from SharedPreferences.
  static Future<PrinterSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final paperSize = p.getString('ps_paper_size') ?? '57mm';

    // v2 migration: reset wasteful defaults (feedLines 3→1, autoCut true→false)
    const int _settingsVersion = 2;
    if ((p.getInt('ps_version') ?? 1) < _settingsVersion) {
      await p.setInt('ps_feed_lines', 1);
      await p.setBool('ps_auto_cut', false);
      await p.setInt('ps_version', _settingsVersion);
    }

    return PrinterSettings(
      paperSize: paperSize,
      paperWidthDots: dotsForPaperSize(paperSize),
      marginLeft: p.getDouble('ps_margin_left') ?? 0,
      marginRight: p.getDouble('ps_margin_right') ?? 0,
      marginTop: p.getDouble('ps_margin_top') ?? 0,
      marginBottom: p.getDouble('ps_margin_bottom') ?? 0,
      showLogo: p.getBool('ps_show_logo') ?? false,
      showAddress: p.getBool('ps_show_address') ?? true,
      showPhone: p.getBool('ps_show_phone') ?? true,
      showDescription: p.getBool('ps_show_description') ?? true,
      showTransactionId: p.getBool('ps_show_txn_id') ?? true,
      showDateTime: p.getBool('ps_show_datetime') ?? true,
      showMemberInfo: p.getBool('ps_show_member') ?? true,
      showPaymentDetails: p.getBool('ps_show_payment') ?? true,
      footerText: p.getString('ps_footer_text') ?? 'Terima kasih atas kunjungan Anda!',
      footerSecondLine: p.getString('ps_footer_second') ?? '— Powered by Metal —',
      feedLinesAfter: p.getInt('ps_feed_lines') ?? 1,
      autoCut: p.getBool('ps_auto_cut') ?? false,
      printDuplicate: p.getBool('ps_print_dup') ?? false,
      fontScale: p.getInt('ps_font_scale') ?? 1,
      savedPrinterName: p.getString('ps_printer_name'),
      savedPrinterAddress: p.getString('ps_printer_addr'),
      autoConnect: p.getBool('ps_auto_connect') ?? false,
    );
  }

  /// Save to SharedPreferences.
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ps_paper_size', paperSize);
    await p.setDouble('ps_margin_left', marginLeft);
    await p.setDouble('ps_margin_right', marginRight);
    await p.setDouble('ps_margin_top', marginTop);
    await p.setDouble('ps_margin_bottom', marginBottom);
    await p.setBool('ps_show_logo', showLogo);
    await p.setBool('ps_show_address', showAddress);
    await p.setBool('ps_show_phone', showPhone);
    await p.setBool('ps_show_description', showDescription);
    await p.setBool('ps_show_txn_id', showTransactionId);
    await p.setBool('ps_show_datetime', showDateTime);
    await p.setBool('ps_show_member', showMemberInfo);
    await p.setBool('ps_show_payment', showPaymentDetails);
    await p.setString('ps_footer_text', footerText);
    await p.setString('ps_footer_second', footerSecondLine);
    await p.setInt('ps_feed_lines', feedLinesAfter);
    await p.setBool('ps_auto_cut', autoCut);
    await p.setBool('ps_print_dup', printDuplicate);
    await p.setInt('ps_font_scale', fontScale);
    if (savedPrinterName != null) {
      await p.setString('ps_printer_name', savedPrinterName!);
    } else {
      await p.remove('ps_printer_name');
    }
    if (savedPrinterAddress != null) {
      await p.setString('ps_printer_addr', savedPrinterAddress!);
    } else {
      await p.remove('ps_printer_addr');
    }
    await p.setBool('ps_auto_connect', autoConnect);
    paperWidthDots = dotsForPaperSize(paperSize);
  }

  /// Reset to defaults.
  static Future<PrinterSettings> resetToDefaults() async {
    final settings = PrinterSettings();
    await settings.save();
    return settings;
  }
}
