import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/expense_controller.dart';
import '../../models/expense.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/theme.dart';

// Category colour palette — matches expense_list_view.dart
const _categoryColors = <String, Color>{
  'Bahan Baku':    Color(0xFF10B981),
  'Listrik & Air': Color(0xFFF59E0B),
  'Sewa':          Color(0xFF8B5CF6),
  'Kemasan':       Color(0xFF06B6D4),
  'Transportasi':  Color(0xFFF97316),
  'Gaji':          Color(0xFF3B82F6),
  'Peralatan':     Color(0xFFEC4899),
  'Lainnya':       Color(0xFF6B7280),
};

const _categoryIcons = <String, IconData>{
  'Bahan Baku':    Icons.inventory_2_outlined,
  'Listrik & Air': Icons.bolt_outlined,
  'Sewa':          Icons.home_outlined,
  'Kemasan':       Icons.shopping_bag_outlined,
  'Transportasi':  Icons.directions_car_outlined,
  'Gaji':          Icons.people_outline,
  'Peralatan':     Icons.build_outlined,
  'Lainnya':       Icons.more_horiz_rounded,
};

Color _colorFor(String c) => _categoryColors[c] ?? const Color(0xFF6B7280);
IconData _iconFor(String c) => _categoryIcons[c] ?? Icons.receipt_outlined;

/// Add / Edit expense form — redesigned Metal style.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _colorFor(_category);
    final cardBg = isDark ? const Color(0xFF0F1117) : Colors.white;
    final scaffoldBg =
        isDark ? const Color(0xFF080B14) : const Color(0xFFF4F6FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Pengeluaran' : 'Tambah Pengeluaran',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: ResponsiveHelper.getButtonWidth(context, tabletPercent: 0.5),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // ── Amount hero ───────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accent.withValues(alpha: isDark ? 0.35 : 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.25)),
                            ),
                            child: Icon(_iconFor(_category),
                                color: accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jumlah Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  _category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Rp ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _amountCtrl,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1F2E),
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                ),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      Divider(
                          color: accent.withValues(alpha: 0.25), height: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Category picker ───────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  label: 'Kategori',
                  icon: Icons.category_outlined,
                  accent: const Color(0xFF8B5CF6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategories.all.map((cat) {
                      final isSelected = _category == cat;
                      final c = _colorFor(cat);
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c
                                : c.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? c
                                  : c.withValues(alpha: 0.25),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _iconFor(cat),
                                size: 14,
                                color: isSelected ? Colors.white : c,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : c,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Nama pengeluaran ──────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  label: 'Nama Pengeluaran',
                  icon: Icons.receipt_long_outlined,
                  accent: AppTheme.dangerColor,
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                    ),
                    decoration: _inputDecor(
                        isDark, 'Contoh: Beli bahan baku tepung'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tanggal ───────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  label: 'Tanggal',
                  icon: Icons.calendar_today_rounded,
                  accent: const Color(0xFF06B6D4),
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded,
                              size: 18, color: Color(0xFF06B6D4)),
                          const SizedBox(width: 10),
                          Text(
                            '${_date.day} ${_monthName(_date.month)} ${_date.year}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1F2E),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Ganti',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF06B6D4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Catatan ───────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  label: 'Catatan (opsional)',
                  icon: Icons.notes_rounded,
                  accent: const Color(0xFFF59E0B),
                  child: TextFormField(
                    controller: _notesCtrl,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                    ),
                    decoration: _inputDecor(
                        isDark, 'Tambahkan catatan detail...'),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Save button ───────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        accent.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _save,
                      borderRadius: BorderRadius.circular(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditing
                                ? Icons.check_circle_outline_rounded
                                : Icons.add_circle_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEditing
                                ? 'Simpan Perubahan'
                                : 'Tambah Pengeluaran',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white24 : Colors.grey.shade400,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _colorFor(_category),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.dangerColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppTheme.dangerColor, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return names[m];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = context.read<ExpenseController>();

    if (isEditing) {
      final updated = widget.expense!.copyWith(
        name: _nameCtrl.text.trim(),
        category: _category,
        amount: double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0,
        date: _date,
        notes: _notesCtrl.text.trim(),
      );
      await ctrl.updateExpense(updated);
    } else {
      await ctrl.addExpense(
        name: _nameCtrl.text.trim(),
        category: _category,
        amount: double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0,
        date: _date,
        notes: _notesCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

// ── Reusable section card ──────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final String label;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.cardBg,
    required this.label,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
