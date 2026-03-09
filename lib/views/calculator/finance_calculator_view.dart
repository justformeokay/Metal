import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calc_history.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';

/// Finance calculator with multiple modes: kembalian, diskon, margin, pajak, markup.
class FinanceCalculatorView extends StatefulWidget {
  const FinanceCalculatorView({super.key});

  @override
  State<FinanceCalculatorView> createState() => _FinanceCalculatorViewState();
}

class _FinanceCalculatorViewState extends State<FinanceCalculatorView>
    with TickerProviderStateMixin {
  final _db = DatabaseService();

  // Calculator modes
  static const _modes = [
    _CalcMode('Kembalian', Icons.payments_rounded, Color(0xFF10B981)),
    _CalcMode('Diskon', Icons.discount_rounded, Color(0xFFF59E0B)),
    _CalcMode('Margin', Icons.trending_up_rounded, Color(0xFF3B82F6)),
    _CalcMode('Pajak', Icons.receipt_long_rounded, Color(0xFFEF4444)),
    _CalcMode('Markup', Icons.price_change_rounded, Color(0xFF8B5CF6)),
  ];

  int _selectedMode = 0;
  String? _resultText;
  String? _resultDetail;
  List<CalcHistory> _history = [];
  bool _showHistory = false;

  // Controllers per mode
  final _kembalianBayar = TextEditingController();
  final _kembalianTotal = TextEditingController();
  final _diskonHarga = TextEditingController();
  final _diskonPersen = TextEditingController();
  final _marginCost = TextEditingController();
  final _marginSell = TextEditingController();
  final _pajakHarga = TextEditingController();
  final _pajakPersen = TextEditingController();
  final _markupCost = TextEditingController();
  final _markupPersen = TextEditingController();

  // Animations
  late AnimationController _resultAnimController;
  late Animation<double> _resultSlide;
  late Animation<double> _resultFade;

  // Button scale animations
  final Map<String, AnimationController> _btnControllers = {};

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOutCubic),
    );
    _resultFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOut),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _resultAnimController.dispose();
    for (final c in _btnControllers.values) {
      c.dispose();
    }
    _kembalianBayar.dispose();
    _kembalianTotal.dispose();
    _diskonHarga.dispose();
    _diskonPersen.dispose();
    _marginCost.dispose();
    _marginSell.dispose();
    _pajakHarga.dispose();
    _pajakPersen.dispose();
    _markupCost.dispose();
    _markupPersen.dispose();
    super.dispose();
  }

  AnimationController _getBtnController(String key) {
    if (!_btnControllers.containsKey(key)) {
      _btnControllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.0,
        upperBound: 0.08,
      );
    }
    return _btnControllers[key]!;
  }

  Future<void> _loadHistory() async {
    final history = await _db.getCalcHistory();
    if (mounted) setState(() => _history = history);
  }

  Future<void> _saveHistory(String type, String expression, String result) async {
    await _db.insertCalcHistory(CalcHistory(
      type: type,
      expression: expression,
      result: result,
      createdAt: DateTime.now(),
    ));
    _loadHistory();
  }

  void _clearFields() {
    _kembalianBayar.clear();
    _kembalianTotal.clear();
    _diskonHarga.clear();
    _diskonPersen.clear();
    _marginCost.clear();
    _marginSell.clear();
    _pajakHarga.clear();
    _pajakPersen.clear();
    _markupCost.clear();
    _markupPersen.clear();
    setState(() {
      _resultText = null;
      _resultDetail = null;
    });
  }

  double _parse(TextEditingController c) {
    final text = c.text.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');
    return double.tryParse(text) ?? 0;
  }

  void _calculate() {
    String type = _modes[_selectedMode].label;
    String expression = '';
    String result = '';

    switch (_selectedMode) {
      case 0: // Kembalian
        final bayar = _parse(_kembalianBayar);
        final total = _parse(_kembalianTotal);
        if (bayar <= 0 || total <= 0) return;
        final kembalian = bayar - total;
        expression = 'Bayar ${formatCurrency(bayar)} − Total ${formatCurrency(total)}';
        if (kembalian >= 0) {
          result = formatCurrency(kembalian);
          _resultText = result;
          _resultDetail = kembalian == 0 ? 'Pas, tidak ada kembalian' : 'Kembalian yang harus diberikan';
        } else {
          result = 'Kurang ${formatCurrency(kembalian.abs())}';
          _resultText = result;
          _resultDetail = 'Uang pembayaran tidak cukup';
        }
        break;

      case 1: // Diskon
        final harga = _parse(_diskonHarga);
        final persen = _parse(_diskonPersen);
        if (harga <= 0 || persen <= 0) return;
        final potongan = harga * persen / 100;
        final setelah = harga - potongan;
        expression = '${formatCurrency(harga)} diskon $persen%';
        result = formatCurrency(setelah);
        _resultText = result;
        _resultDetail = 'Hemat ${formatCurrency(potongan)}';
        break;

      case 2: // Margin
        final cost = _parse(_marginCost);
        final sell = _parse(_marginSell);
        if (cost <= 0 || sell <= 0) return;
        final profit = sell - cost;
        final margin = (profit / sell) * 100;
        expression = 'Jual ${formatCurrency(sell)} − Modal ${formatCurrency(cost)}';
        result = '${margin.toStringAsFixed(1)}%';
        _resultText = result;
        _resultDetail = 'Laba ${formatCurrency(profit)} per item';
        break;

      case 3: // Pajak
        final harga = _parse(_pajakHarga);
        final persen = _parse(_pajakPersen);
        if (harga <= 0 || persen <= 0) return;
        final pajak = harga * persen / 100;
        final total = harga + pajak;
        expression = '${formatCurrency(harga)} + pajak $persen%';
        result = formatCurrency(total);
        _resultText = result;
        _resultDetail = 'Pajak ${formatCurrency(pajak)}';
        break;

      case 4: // Markup
        final cost = _parse(_markupCost);
        final persen = _parse(_markupPersen);
        if (cost <= 0 || persen <= 0) return;
        final markup = cost * persen / 100;
        final sell = cost + markup;
        expression = '${formatCurrency(cost)} + markup $persen%';
        result = formatCurrency(sell);
        _resultText = result;
        _resultDetail = 'Harga jual yang disarankan';
        break;
    }

    if (result.isNotEmpty) {
      _resultAnimController.reset();
      _resultAnimController.forward();
      _saveHistory(type, expression, result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Keuangan'),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.calculate_rounded : Icons.history_rounded),
            tooltip: _showHistory ? 'Kalkulator' : 'Riwayat',
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
          if (!_showHistory)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset',
              onPressed: _clearFields,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showHistory ? _buildHistory(theme, isDark) : _buildCalculator(theme, isDark),
      ),
    );
  }

  // ─── Calculator Body ────────────────────────────────────────

  Widget _buildCalculator(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('calc'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selector chips
          _buildModeSelector(theme, isDark),
          const SizedBox(height: 20),
          // Input fields
          _buildInputCard(theme, isDark),
          const SizedBox(height: 16),
          // Calculate button
          _buildCalcButton(theme),
          const SizedBox(height: 16),
          // Result
          if (_resultText != null) _buildResultCard(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final mode = _modes[i];
          final selected = i == _selectedMode;
          return _AnimatedTapButton(
            controller: _getBtnController('mode_$i'),
            onTap: () {
              if (i != _selectedMode) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedMode = i;
                  _resultText = null;
                  _resultDetail = null;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 80,
              decoration: BoxDecoration(
                color: selected
                    ? mode.color.withValues(alpha: 0.15)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? mode.color : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? mode.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(mode.icon, size: 22, color: selected ? mode.color : theme.textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? mode.color : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme, bool isDark) {
    final mode = _modes[_selectedMode];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: mode.color.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mode.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(mode.icon, color: mode.color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Hitung ${mode.label}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._buildFields(mode),
        ],
      ),
    );
  }

  List<Widget> _buildFields(_CalcMode mode) {
    switch (_selectedMode) {
      case 0:
        return [
          _buildTextField(_kembalianTotal, 'Total Belanja', 'Rp 0', Icons.shopping_cart_rounded),
          const SizedBox(height: 14),
          _buildTextField(_kembalianBayar, 'Uang Diterima', 'Rp 0', Icons.payments_rounded),
        ];
      case 1:
        return [
          _buildTextField(_diskonHarga, 'Harga Asli', 'Rp 0', Icons.sell_rounded),
          const SizedBox(height: 14),
          _buildTextField(_diskonPersen, 'Diskon (%)', '0', Icons.percent_rounded, suffix: '%'),
        ];
      case 2:
        return [
          _buildTextField(_marginCost, 'Harga Modal', 'Rp 0', Icons.inventory_rounded),
          const SizedBox(height: 14),
          _buildTextField(_marginSell, 'Harga Jual', 'Rp 0', Icons.sell_rounded),
        ];
      case 3:
        return [
          _buildTextField(_pajakHarga, 'Harga Sebelum Pajak', 'Rp 0', Icons.local_offer_rounded),
          const SizedBox(height: 14),
          _buildTextField(_pajakPersen, 'Tarif Pajak (%)', '0', Icons.percent_rounded, suffix: '%'),
        ];
      case 4:
        return [
          _buildTextField(_markupCost, 'Harga Modal', 'Rp 0', Icons.inventory_rounded),
          const SizedBox(height: 14),
          _buildTextField(_markupPersen, 'Markup (%)', '0', Icons.percent_rounded, suffix: '%'),
        ];
      default:
        return [];
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixText: suffix,
      ),
      onSubmitted: (_) => _calculate(),
    );
  }

  Widget _buildCalcButton(ThemeData theme) {
    final mode = _modes[_selectedMode];
    return _AnimatedTapButton(
      controller: _getBtnController('calc'),
      onTap: () {
        HapticFeedback.mediumImpact();
        _calculate();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mode.color, mode.color.withValues(alpha: 0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: mode.color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Hitung',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, bool isDark) {
    final mode = _modes[_selectedMode];
    return AnimatedBuilder(
      animation: _resultAnimController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _resultSlide.value),
          child: Opacity(
            opacity: _resultFade.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mode.color.withValues(alpha: isDark ? 0.2 : 0.08),
              mode.color.withValues(alpha: isDark ? 0.08 : 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mode.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mode.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: mode.color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              _resultText ?? '',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: mode.color,
                letterSpacing: -0.5,
              ),
            ),
            if (_resultDetail != null) ...[
              const SizedBox(height: 6),
              Text(
                _resultDetail!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── History Panel ──────────────────────────────────────────

  Widget _buildHistory(ThemeData theme, bool isDark) {
    if (_history.isEmpty) {
      return Center(
        key: const ValueKey('history'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('history'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Text(
                'Riwayat Perhitungan',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await _db.clearCalcHistory();
                  _loadHistory();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus Semua'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: _history.length,
            itemBuilder: (context, i) {
              final h = _history[i];
              final mode = _modes.firstWhere(
                (m) => m.label == h.type,
                orElse: () => _modes[0],
              );
              return _HistoryTile(entry: h, mode: mode, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Mode Descriptor ────────────────────────────────────────

class _CalcMode {
  final String label;
  final IconData icon;
  final Color color;
  const _CalcMode(this.label, this.icon, this.color);
}

// ─── Animated Tap Button ────────────────────────────────────

class _AnimatedTapButton extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedTapButton({
    required this.controller,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) {
        controller.reverse();
        onTap();
      },
      onTapCancel: () => controller.reverse(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - controller.value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

// ─── History Tile ───────────────────────────────────────────

class _HistoryTile extends StatefulWidget {
  final CalcHistory entry;
  final _CalcMode mode;
  final bool isDark;
  const _HistoryTile({required this.entry, required this.mode, required this.isDark});

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.mode.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.mode.icon, color: widget.mode.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.mode.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.entry.type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.mode.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimeAgo(widget.entry.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.entry.expression,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '= ${widget.entry.result}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.mode.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(dt);
  }
}
