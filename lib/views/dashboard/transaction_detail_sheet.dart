import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';

/// Bottom sheet for displaying transaction details
class TransactionDetailSheet extends StatelessWidget {
  final SalesTransaction transaction;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // ─── Header ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Transaksi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Selasa, ${formatDateTime(transaction.date)}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Transaction Items ──────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table header
                    Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Produk',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Harga',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Items
                    ...transaction.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    formatCurrency(item.unitPrice),
                                    style: const TextStyle(
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    formatCurrency(item.subtotal),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            // Discount info
                            if (item.hasDiscount)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  item.discountPercent > 0
                                      ? 'Diskon ${item.discountPercent.toStringAsFixed(0)}% (-${formatCurrency(item.totalDiscount)})'
                                      : 'Diskon (-${formatCurrency(item.totalDiscount)})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Financial Summary ──────────────────────
              Column(
                children: [
                  _buildSummaryRow(
                    label: 'Total Penjualan',
                    value: formatCurrency(transaction.totalAmount),
                    isHighlight: false,
                  ),
                  if (transaction.totalDiscount > 0) ...[
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      label: 'Total Diskon',
                      value: '-${formatCurrency(transaction.totalDiscount)}',
                      isHighlight: false,
                      color: Colors.red,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    label: 'Uang Diterima',
                    value: formatCurrency(transaction.amountPaid),
                    isHighlight: false,
                  ),
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    label: 'Kembalian',
                    value: formatCurrency(transaction.change),
                    isHighlight: false,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: AppTheme.border.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    label: 'Laba Kotor',
                    value: formatCurrency(transaction.profit),
                    isHighlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Payment Method ─────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getPaymentMethodBgColor(transaction.paymentMethod)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPaymentMethodColor(transaction.paymentMethod)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.paymentMethod,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _getPaymentMethodColor(transaction.paymentMethod),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getPaymentMethodBgColor(transaction.paymentMethod)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getPaymentMethodIcon(transaction.paymentMethod),
                        color: _getPaymentMethodColor(transaction.paymentMethod),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Transaction ID ─────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ID: ${transaction.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required bool isHighlight,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isHighlight ? Colors.white : AppTheme.textSecondary,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: color ?? (isHighlight ? Colors.green : Colors.white),
          ),
        ),
      ],
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'Tunai':
        return Colors.green;
      case 'QRIS':
        return Colors.blue;
      case 'Gopay':
        return const Color(0xFF00B4E4);
      case 'OVO':
        return const Color(0xFF662D91);
      case 'Dana':
        return const Color(0xFF1C5FCF);
      case 'Transfer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentMethodBgColor(String method) {
    switch (method) {
      case 'Tunai':
        return Colors.green;
      case 'QRIS':
        return Colors.blue;
      case 'Gopay':
        return const Color(0xFF00B4E4);
      case 'OVO':
        return const Color(0xFF662D91);
      case 'Dana':
        return const Color(0xFF1C5FCF);
      case 'Transfer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Tunai':
        return Icons.money_rounded;
      case 'QRIS':
        return Icons.qr_code_2_rounded;
      case 'Gopay':
        return Icons.payment_rounded;
      case 'OVO':
        return Icons.payment_rounded;
      case 'Dana':
        return Icons.payment_rounded;
      case 'Transfer':
        return Icons.account_balance_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}
