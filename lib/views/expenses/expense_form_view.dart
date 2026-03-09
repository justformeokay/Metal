import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/expense_controller.dart';
import '../../models/expense.dart';

/// Add / Edit expense form.
class ExpenseFormView extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormView({super.key, this.expense});

  @override
  State<ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends State<ExpenseFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  late String _category;
  late DateTime _date;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.expense?.name ?? '');
    _amountCtrl = TextEditingController(
        text: widget.expense?.amount.toStringAsFixed(0) ?? '');
    _notesCtrl = TextEditingController(text: widget.expense?.notes ?? '');
    _category = widget.expense?.category ?? ExpenseCategories.all.first;
    _date = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Pengeluaran',
                hintText: 'Contoh: Beli bahan baku',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: ExpenseCategories.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? ExpenseCategories.all.first),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Tanggal'),
              subtitle: Text(
                '${_date.day}/${_date.month}/${_date.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Catatan tambahan...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                    isEditing ? 'Simpan Perubahan' : 'Tambah Pengeluaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = context.read<ExpenseController>();

    if (isEditing) {
      final updated = widget.expense!.copyWith(
        name: _nameCtrl.text.trim(),
        category: _category,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        date: _date,
        notes: _notesCtrl.text.trim(),
      );
      await ctrl.updateExpense(updated);
    } else {
      await ctrl.addExpense(
        name: _nameCtrl.text.trim(),
        category: _category,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        date: _date,
        notes: _notesCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
