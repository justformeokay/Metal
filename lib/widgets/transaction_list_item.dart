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
      title: Text(
        '${transaction.items.length} item · ${formatTime(transaction.date)}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        transaction.items.map((i) => i.productName).join(', '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
}
