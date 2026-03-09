import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// PDF report generation service.
class PdfService {
  /// Generate and share/print a business report PDF.
  static Future<void> generateReport({
    required String periodLabel,
    required double totalSales,
    required double totalCost,
    required double totalExpenses,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> expenseBreakdown,
    required DateTimeRange dateRange,
  }) async {
    final pdf = pw.Document();
    final profit = totalSales - totalCost - totalExpenses;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                'Laporan Bisnis - $periodLabel',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${formatDate(dateRange.start)} - ${formatDate(dateRange.end)}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Summary
              pw.Text('Ringkasan Keuangan',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _pdfRow('Total Penjualan', formatCurrency(totalSales)),
              _pdfRow('HPP (Modal)', formatCurrency(totalCost)),
              _pdfRow('Total Pengeluaran', formatCurrency(totalExpenses)),
              pw.Divider(),
              _pdfRow('Laba Bersih', formatCurrency(profit),
                  bold: true),
              pw.SizedBox(height: 24),

              // Top products
              if (topProducts.isNotEmpty) ...[
                pw.Text('Produk Terlaris',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _cell('No', bold: true),
                        _cell('Produk', bold: true),
                        _cell('Qty', bold: true),
                        _cell('Revenue', bold: true),
                      ],
                    ),
                    ...topProducts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      return pw.TableRow(children: [
                        _cell('${i + 1}'),
                        _cell(p['productName'] as String),
                        _cell('${(p['totalQty'] as num).toInt()}'),
                        _cell(formatCurrency(
                            (p['totalRevenue'] as num).toDouble())),
                      ]);
                    }),
                  ],
                ),
                pw.SizedBox(height: 24),
              ],

              // Expense breakdown
              if (expenseBreakdown.isNotEmpty) ...[
                pw.Text('Rincian Pengeluaran',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...expenseBreakdown.map((e) => _pdfRow(
                      e['category'] as String,
                      formatCurrency((e['total'] as num).toDouble()),
                    )),
              ],

              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Dibuat oleh LabaKu · ${formatDateTime(DateTime.now())}',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    // Show print/share dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_${periodLabel}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: bold
                  ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                  : null),
          pw.Text(value,
              style: bold
                  ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                  : null),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: bold ? pw.FontWeight.bold : null,
          )),
    );
  }
}
