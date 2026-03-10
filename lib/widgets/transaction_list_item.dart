import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../models/transaction.dart';

/// Transaction list item widget.
class TransactionListItem extends StatelessWidget {
  final SalesTransaction transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.receipt_long_rounded,
          color: Colors.green,
          size: 22,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${transaction.items.length} item · ${formatTime(transaction.date)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPaymentMethodColor(transaction.paymentMethod).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  transaction.paymentMethod,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getPaymentMethodColor(transaction.paymentMethod),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          transaction.items.map((i) => i.productName).join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ),
      trailing: Text(
        formatCurrency(transaction.totalAmount),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.green,
        ),
      ),
    );
  }

  /// Get color for payment method badge
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
}
