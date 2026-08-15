class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.memo,
    required this.date,
  });

  final String id;
  final int amount;
  final String category;
  final String memo;
  final DateTime date;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'memo': memo,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: map['amount'] as int,
      category: map['category'] as String,
      memo: map['memo'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Expense copyWith({
    int? amount,
    String? category,
    String? memo,
    DateTime? date,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      memo: memo ?? this.memo,
      date: date ?? this.date,
    );
  }
}
