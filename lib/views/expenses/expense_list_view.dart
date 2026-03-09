import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/expense_controller.dart';
import '../../models/expense.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import 'expense_form_view.dart';

/// Expense list view with add/edit/delete.
class ExpenseListView extends StatefulWidget {
  const ExpenseListView({super.key});

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseController>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExpenseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ctrl.expenses.isEmpty
              ? EmptyState(
                  icon: Icons.money_off_rounded,
                  title: 'Belum ada pengeluaran',
                  subtitle: 'Catat pengeluaran bisnis kamu',
                  action: ElevatedButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Pengeluaran'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ctrl.expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final expense = ctrl.expenses[index];
                    return _ExpenseCard(
                      expense: expense,
                      onTap: () => _openForm(context, expense: expense),
                      onDelete: () =>
                          _confirmDelete(context, expense.id, expense.name),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_expense',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {Expense? expense}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormView(expense: expense)),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text('Yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseController>().deleteExpense(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ExpenseCard({
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_outlined,
                  color: AppTheme.dangerColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(expense.category,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ),
                      const SizedBox(width: 8),
                      Text(formatDate(expense.date),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(expense.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dangerColor,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline,
                      size: 18, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
