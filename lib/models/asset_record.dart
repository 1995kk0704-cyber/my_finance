class AssetRecord {
  const AssetRecord({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
  });

  final String id;
  final String name;
  final int amount;
  final DateTime date;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory AssetRecord.fromMap(Map<String, dynamic> map) {
    return AssetRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: map['amount'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }

  AssetRecord copyWith({String? name, int? amount, DateTime? date}) {
    return AssetRecord(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
