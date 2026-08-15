import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/fixed_cost.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.selectedMonth,
    required this.budget,
    required this.income,
    required this.expenses,
    required this.fixedCosts,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSettings,
  });

  final DateTime selectedMonth;
  final int budget;
  final int income;
  final List<Expense> expenses;
  final List<FixedCost> fixedCosts;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onSettings;

  static final NumberFormat _moneyFormat = NumberFormat('#,###');

  int get variableTotal {
    return expenses.fold(0, (total, expense) => total + expense.amount);
  }

  int get fixedTotal {
    return fixedCosts
        .where((fixedCost) => fixedCost.isActive)
        .fold(0, (total, fixedCost) => total + fixedCost.amount);
  }

  int get spendingTotal => variableTotal + fixedTotal;

  Map<String, int> get categoryTotals {
    final Map<String, int> totals = {};

    for (final Expense expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    for (final FixedCost fixedCost in fixedCosts.where(
      (item) => item.isActive,
    )) {
      totals[fixedCost.category] =
          (totals[fixedCost.category] ?? 0) + fixedCost.amount;
    }

    return totals;
  }

  Color _categoryColor(int index) {
    const List<Color> colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
    ];

    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final int remaining = budget - spendingTotal;
    final Map<String, int> totals = categoryTotals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat('yyyy年M月').format(selectedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            color: remaining >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('今月の残り予算'),
                  const SizedBox(height: 8),
                  Text(
                    '¥${_moneyFormat.format(remaining)}',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: remaining >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MoneyCard(
                  title: '予算',
                  amount: budget,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoneyCard(
                  title: '支出',
                  amount: spendingTotal,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MoneyCard(
                  title: '収入',
                  amount: income,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoneyCard(
                  title: '固定費',
                  amount: fixedTotal,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'カテゴリ別支出',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (totals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('支出を登録すると円グラフが表示されます')),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 45,
                          sectionsSpace: 2,
                          sections: totals.entries.toList().asMap().entries.map(
                            (entry) {
                              final int index = entry.key;
                              final MapEntry<String, int> item = entry.value;

                              return PieChartSectionData(
                                value: item.value.toDouble(),
                                title: item.key,
                                radius: 75,
                                color: _categoryColor(index),
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...totals.entries.toList().asMap().entries.map((entry) {
                      final int index = entry.key;
                      final MapEntry<String, int> item = entry.value;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 8,
                          backgroundColor: _categoryColor(index),
                        ),
                        title: Text(item.key),
                        trailing: Text('¥${_moneyFormat.format(item.value)}'),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            '最近の支出',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('登録された支出はありません')),
              ),
            )
          else
            ...expenses
                .take(3)
                .map(
                  (expense) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long),
                      ),
                      title: Text(expense.category),
                      subtitle: Text(
                        '${DateFormat('M月d日').format(expense.date)}　'
                        '${expense.memo.isEmpty ? 'メモなし' : expense.memo}',
                      ),
                      trailing: Text(
                        '¥${_moneyFormat.format(expense.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final NumberFormat format = NumberFormat('#,###');

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                '¥${format.format(amount)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
