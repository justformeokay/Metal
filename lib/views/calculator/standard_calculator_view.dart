import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calc_history.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';

/// iOS-style standard calculator with swipe-to-delete and history.
class StandardCalculatorView extends StatefulWidget {
  const StandardCalculatorView({super.key});

  @override
  State<StandardCalculatorView> createState() => _StandardCalculatorViewState();
}

class _StandardCalculatorViewState extends State<StandardCalculatorView>
    with TickerProviderStateMixin {
  final _db = DatabaseService();

  String _display = '0';
  String _expression = '';
  double _firstOperand = 0;
  String _operator = '';
  bool _shouldResetDisplay = false;
  bool _showHistory = false;
  List<CalcHistory> _history = [];

  // Result animation
  late AnimationController _resultAnim;
  late Animation<double> _resultScale;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resultScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnim, curve: Curves.elasticOut),
    );
    _resultAnim.value = 1.0;
    _loadHistory();
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _db.getCalcHistory();
    if (mounted) setState(() => _history = history);
  }

  void _onDigit(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        if (_display == '0' && digit != '.') {
          _display = digit;
        } else if (digit == '.' && _display.contains('.')) {
          return;
        } else {
          _display += digit;
        }
      }
    });
  }

  void _onOperator(String op) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_operator.isNotEmpty && !_shouldResetDisplay) {
        _calculateResult(saveHistory: false);
      }
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _expression = '${_formatNumber(_firstOperand)} $op';
      _shouldResetDisplay = true;
    });
  }

  void _onEquals() {
    HapticFeedback.mediumImpact();
    if (_operator.isEmpty) return;
    _calculateResult(saveHistory: true);
  }

  void _calculateResult({required bool saveHistory}) {
    final second = double.tryParse(_display) ?? 0;
    double result = 0;

    final fullExpression = '$_expression ${_formatNumber(second)}';

    switch (_operator) {
      case '+':
        result = _firstOperand + second;
        break;
      case '−':
        result = _firstOperand - second;
        break;
      case '×':
        result = _firstOperand * second;
        break;
      case '÷':
        if (second == 0) {
          setState(() {
            _display = 'Error';
            _operator = '';
            _expression = '';
            _shouldResetDisplay = true;
          });
          return;
        }
        result = _firstOperand / second;
        break;
    }

    setState(() {
      _display = _formatNumber(result);
      _firstOperand = result;
      _operator = '';
      _expression = '';
      _shouldResetDisplay = true;
    });

    _resultAnim.reset();
    _resultAnim.forward();

    if (saveHistory) {
      _db.insertCalcHistory(CalcHistory(
        type: 'Kalkulator',
        expression: fullExpression,
        result: _formatNumber(result),
        createdAt: DateTime.now(),
      ));
      _loadHistory();
    }
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    setState(() {
      _display = '0';
      _firstOperand = 0;
      _operator = '';
      _expression = '';
      _shouldResetDisplay = false;
    });
  }

  void _onToggleSign() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_display != '0') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      }
    });
  }

  void _onPercent() {
    HapticFeedback.lightImpact();
    final val = double.tryParse(_display) ?? 0;
    setState(() {
      _display = _formatNumber(val / 100);
      _shouldResetDisplay = true;
    });
  }

  void _onDeleteDigit() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
        if (_display == '-') _display = '0';
      } else {
        _display = '0';
      }
    });
  }

  String _formatNumber(double val) {
    if (val == val.truncateToDouble() && !val.isInfinite && !val.isNaN) {
      return val.toInt().toString();
    }
    // Remove trailing zeros
    String s = val.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFF1C1C1E),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showHistory
              ? _buildHistoryPanel(isDark)
              : _buildCalculatorBody(isDark),
        ),
      ),
    );
  }

  Widget _buildCalculatorBody(bool isDark) {
    return Column(
      key: const ValueKey('calc'),
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                onPressed: () => setState(() => _showHistory = true),
              ),
            ],
          ),
        ),

        // Display area — swipe right to delete digit
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                _onDeleteDigit();
              }
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expression.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _expression,
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _resultAnim,
                    builder: (context, child) => Transform.scale(
                      scale: _resultScale.value,
                      alignment: Alignment.centerRight,
                      child: child,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _display,
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Button grid
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              _buildButtonRow([
                _CalcBtn('C', _BtnType.function),
                _CalcBtn('+/−', _BtnType.function),
                _CalcBtn('%', _BtnType.function),
                _CalcBtn('÷', _BtnType.operator, isActive: _operator == '÷'),
              ]),
              const SizedBox(height: 12),
              _buildButtonRow([
                _CalcBtn('7', _BtnType.number),
                _CalcBtn('8', _BtnType.number),
                _CalcBtn('9', _BtnType.number),
                _CalcBtn('×', _BtnType.operator, isActive: _operator == '×'),
              ]),
              const SizedBox(height: 12),
              _buildButtonRow([
                _CalcBtn('4', _BtnType.number),
                _CalcBtn('5', _BtnType.number),
                _CalcBtn('6', _BtnType.number),
                _CalcBtn('−', _BtnType.operator, isActive: _operator == '−'),
              ]),
              const SizedBox(height: 12),
              _buildButtonRow([
                _CalcBtn('1', _BtnType.number),
                _CalcBtn('2', _BtnType.number),
                _CalcBtn('3', _BtnType.number),
                _CalcBtn('+', _BtnType.operator, isActive: _operator == '+'),
              ]),
              const SizedBox(height: 12),
              _buildBottomRow(),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildButtonRow(List<_CalcBtn> buttons) {
    return Row(
      children: buttons.map((btn) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildButton(btn),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        // 0 button — takes 2 columns
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildButton(
              _CalcBtn('0', _BtnType.number),
              isWide: true,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildButton(_CalcBtn('.', _BtnType.number)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildButton(_CalcBtn('=', _BtnType.equals)),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(_CalcBtn btn, {bool isWide = false}) {
    Color bgColor;
    Color textColor;
    double fontSize;

    switch (btn.type) {
      case _BtnType.number:
        bgColor = const Color(0xFF333333);
        textColor = Colors.white;
        fontSize = 30;
        break;
      case _BtnType.function:
        bgColor = const Color(0xFFA5A5A5);
        textColor = Colors.black;
        fontSize = btn.label == '+/−' ? 24 : 28;
        break;
      case _BtnType.operator:
        bgColor = btn.isActive ? Colors.white : const Color(0xFFFF9F0A);
        textColor = btn.isActive ? const Color(0xFFFF9F0A) : Colors.white;
        fontSize = 32;
        break;
      case _BtnType.equals:
        bgColor = const Color(0xFF34C759);
        textColor = Colors.white;
        fontSize = 32;
        break;
    }

    return _AnimatedCalcButton(
      label: btn.label,
      bgColor: bgColor,
      textColor: textColor,
      fontSize: fontSize,
      isWide: isWide,
      onTap: () => _handleButtonTap(btn.label),
    );
  }

  void _handleButtonTap(String label) {
    switch (label) {
      case 'C':
        _onClear();
        break;
      case '+/−':
        _onToggleSign();
        break;
      case '%':
        _onPercent();
        break;
      case '÷':
      case '×':
      case '−':
      case '+':
        _onOperator(label);
        break;
      case '=':
        _onEquals();
        break;
      case '.':
        _onDigit('.');
        break;
      default:
        _onDigit(label);
    }
  }

  // ─── History Panel ──────────────────────────────────────────

  Widget _buildHistoryPanel(bool isDark) {
    return Column(
      key: const ValueKey('history'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: () => setState(() => _showHistory = false),
              ),
              const SizedBox(width: 8),
              const Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_history.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await _db.clearCalcHistory();
                    _loadHistory();
                  },
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(color: Color(0xFFFF453A)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 64, color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _history.length,
                  itemBuilder: (context, i) {
                    final h = _history[i];
                    return _HistoryItem(entry: h);
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Button Types ───────────────────────────────────────────

enum _BtnType { number, function, operator, equals }

class _CalcBtn {
  final String label;
  final _BtnType type;
  final bool isActive;
  const _CalcBtn(this.label, this.type, {this.isActive = false});
}

// ─── Animated Calculator Button ─────────────────────────────

class _AnimatedCalcButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double fontSize;
  final bool isWide;
  final VoidCallback onTap;

  const _AnimatedCalcButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.fontSize,
    required this.isWide,
    required this.onTap,
  });

  @override
  State<_AnimatedCalcButton> createState() => _AnimatedCalcButtonState();
}

class _AnimatedCalcButtonState extends State<_AnimatedCalcButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _brightness;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
    _brightness = Tween<double>(begin: 0, end: 0.3).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: 72,
              alignment: widget.isWide ? Alignment.centerLeft : Alignment.center,
              padding: widget.isWide ? const EdgeInsets.only(left: 28) : null,
              decoration: BoxDecoration(
                color: Color.lerp(
                  widget.bgColor,
                  Colors.white,
                  _brightness.value,
                ),
                borderRadius: BorderRadius.circular(widget.isWide ? 36 : 36),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w400,
                  color: widget.textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── History Item ───────────────────────────────────────────

class _HistoryItem extends StatefulWidget {
  final CalcHistory entry;
  const _HistoryItem({required this.entry});

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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
    return FadeTransition(
      opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.entry.type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _typeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(widget.entry.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.entry.expression,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 2),
              Text(
                '= ${widget.entry.result}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (widget.entry.type) {
      case 'Kembalian':
        return const Color(0xFF10B981);
      case 'Diskon':
        return const Color(0xFFF59E0B);
      case 'Margin':
        return const Color(0xFF3B82F6);
      case 'Pajak':
        return const Color(0xFFEF4444);
      case 'Markup':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFFF9F0A);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return formatDate(dt);
  }
}
