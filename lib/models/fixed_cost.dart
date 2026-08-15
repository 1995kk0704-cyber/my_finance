class FixedCost {
  const FixedCost({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.isActive,
  });

  final String id;
  final String name;
  final int amount;
  final String category;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'isActive': isActive,
    };
  }

  factory FixedCost.fromMap(Map<String, dynamic> map) {
    return FixedCost(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toInt(),
      category: map['category'] as String,
      isActive: map['isActive'] as bool,
    );
  }

  FixedCost copyWith({
    String? name,
    int? amount,
    String? category,
    bool? isActive,
  }) {
    return FixedCost(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }
}
