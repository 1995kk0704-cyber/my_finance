import 'package:flutter_test/flutter_test.dart';
import 'package:my_finance/models/fixed_cost.dart';

void main() {
  const FixedCost base = FixedCost(
    id: '1',
    name: '保育料',
    amount: 35000,
    category: '保育料',
    isActive: true,
    startMonth: '2026-08',
  );

  test('開始月より前は0円になる', () {
    expect(base.amountForMonth(DateTime(2026, 7)), 0);
    expect(base.amountForMonth(DateTime(2026, 8)), 35000);
  });

  test('この月だけ変更できる', () {
    final FixedCost changed = base.withAmountForMonth(DateTime(2026, 9), 36500);

    expect(changed.amountForMonth(DateTime(2026, 8)), 35000);
    expect(changed.amountForMonth(DateTime(2026, 9)), 36500);
    expect(changed.amountForMonth(DateTime(2026, 10)), 35000);
  });

  test('この月以降を変更できる', () {
    final FixedCost changed = base.withAmountFromMonth(
      DateTime(2026, 10),
      34800,
    );

    expect(changed.amountForMonth(DateTime(2026, 9)), 35000);
    expect(changed.amountForMonth(DateTime(2026, 10)), 34800);
    expect(changed.amountForMonth(DateTime(2027, 1)), 34800);
  });

  test('すべての月を変更すると履歴をリセットする', () {
    final FixedCost changed = base
        .withAmountForMonth(DateTime(2026, 9), 36500)
        .withAmountForAllMonths(40000);

    expect(changed.amountForMonth(DateTime(2025, 1)), 40000);
    expect(changed.amountForMonth(DateTime(2026, 9)), 40000);
  });
}
