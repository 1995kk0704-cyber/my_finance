class FixedCost {
  const FixedCost({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.isActive,
    this.monthlyOverrides = const {},
    this.amountChanges = const {},
    this.startMonth,
  });

  final String id;
  final String name;
  final int amount;
  final String category;
  final bool isActive;
  final Map<String, int> monthlyOverrides;
  final Map<String, int> amountChanges;
  final String? startMonth;

  static String monthKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  int amountForMonth(DateTime date) {
    final String targetKey = monthKey(date);
    final int? overrideAmount = monthlyOverrides[targetKey];

    if (overrideAmount != null) {
      return overrideAmount;
    }

    if (startMonth != null && targetKey.compareTo(startMonth!) < 0) {
      return 0;
    }

    String? latestChangeKey;

    for (final String changeKey in amountChanges.keys) {
      if (changeKey.compareTo(targetKey) <= 0 &&
          (latestChangeKey == null ||
              changeKey.compareTo(latestChangeKey) > 0)) {
        latestChangeKey = changeKey;
      }
    }

    return latestChangeKey == null ? amount : amountChanges[latestChangeKey]!;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'isActive': isActive,
      'monthlyOverrides': monthlyOverrides,
      'amountChanges': amountChanges,
      'startMonth': startMonth,
    };
  }

  factory FixedCost.fromMap(Map<String, dynamic> map) {
    return FixedCost(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toInt(),
      category: map['category'] as String,
      isActive: map['isActive'] as bool,
      monthlyOverrides: _readIntMap(map['monthlyOverrides']),
      amountChanges: _readIntMap(map['amountChanges']),
      startMonth: map['startMonth'] as String?,
    );
  }

  FixedCost copyWith({
    String? name,
    int? amount,
    String? category,
    bool? isActive,
    Map<String, int>? monthlyOverrides,
    Map<String, int>? amountChanges,
    String? startMonth,
    bool clearStartMonth = false,
  }) {
    return FixedCost(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      monthlyOverrides: monthlyOverrides ?? this.monthlyOverrides,
      amountChanges: amountChanges ?? this.amountChanges,
      startMonth: clearStartMonth ? null : startMonth ?? this.startMonth,
    );
  }

  FixedCost withAmountForMonth(DateTime month, int newAmount) {
    final Map<String, int> overrides = Map<String, int>.from(monthlyOverrides);
    overrides[monthKey(month)] = newAmount;

    return copyWith(monthlyOverrides: overrides);
  }

  FixedCost withAmountFromMonth(DateTime month, int newAmount) {
    final String targetKey = monthKey(month);

    final Map<String, int> overrides = Map<String, int>.from(monthlyOverrides)
      ..removeWhere((key, _) => key.compareTo(targetKey) >= 0);

    final Map<String, int> changes = Map<String, int>.from(amountChanges)
      ..removeWhere((key, _) => key.compareTo(targetKey) >= 0)
      ..[targetKey] = newAmount;

    final String? updatedStartMonth =
        startMonth == null || targetKey.compareTo(startMonth!) < 0
        ? targetKey
        : startMonth;

    return copyWith(
      monthlyOverrides: overrides,
      amountChanges: changes,
      startMonth: updatedStartMonth,
    );
  }

  FixedCost withAmountForAllMonths(int newAmount) {
    return copyWith(
      amount: newAmount,
      monthlyOverrides: const {},
      amountChanges: const {},
      clearStartMonth: true,
    );
  }

  static Map<String, int> _readIntMap(dynamic value) {
    if (value is! Map) {
      return {};
    }

    return Map<String, dynamic>.from(
      value,
    ).map((key, amount) => MapEntry(key, (amount as num).toInt()));
  }
}
