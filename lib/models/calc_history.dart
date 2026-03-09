/// Model for finance calculator history entries.
class CalcHistory {
  final int? id;
  final String type; // kembalian, diskon, margin, pajak, markup
  final String expression; // e.g. "Rp 100.000 - Rp 75.000"
  final String result; // e.g. "Rp 25.000"
  final DateTime createdAt;

  CalcHistory({
    this.id,
    required this.type,
    required this.expression,
    required this.result,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'expression': expression,
        'result': result,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CalcHistory.fromMap(Map<String, dynamic> map) => CalcHistory(
        id: map['id'] as int?,
        type: map['type'] as String,
        expression: map['expression'] as String,
        result: map['result'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
