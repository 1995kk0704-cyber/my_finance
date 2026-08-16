import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/fixed_cost.dart';
import '../models/income_record.dart';

enum AnalysisPeriod { oneMonth, oneYear, fiveYears }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    super.key,
    required this.selectedMonth,
    required this.expenses,
    required this.incomeRecords,
    required this.fixedCosts,
  });

  final DateTime selectedMonth;
  final List<Expense> expenses;
  final List<IncomeRecord> incomeRecords;
  final List<FixedCost> fixedCosts;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisPeriod _selectedPeriod = AnalysisPeriod.oneYear;

  final NumberFormat _moneyFormat = NumberFormat('#,###');

  int _activeFixedCostTotalForMonth(DateTime month) {
    return widget.fixedCosts
        .where((fixedCost) => fixedCost.isActive)
        .fold(0, (total, fixedCost) => total + fixedCost.amountForMonth(month));
  }

  List<_ChartData> _createChartData() {
    switch (_selectedPeriod) {
      case AnalysisPeriod.oneMonth:
        return _createMonthlyData();

      case AnalysisPeriod.oneYear:
        return _createYearlyData();

      case AnalysisPeriod.fiveYears:
        return _createFiveYearData();
    }
  }

  List<_ChartData> _createMonthlyData() {
    final int year = widget.selectedMonth.year;
    final int month = widget.selectedMonth.month;

    final int lastDay = DateTime(year, month + 1, 0).day;

    return List.generate(lastDay, (index) {
      final int day = index + 1;

      final int expenseTotal = widget.expenses
          .where(
            (expense) =>
                expense.date.year == year &&
                expense.date.month == month &&
                expense.date.day == day,
          )
          .fold(0, (total, expense) => total + expense.amount);

      final int incomeTotal = widget.incomeRecords
          .where(
            (income) =>
                income.date.year == year &&
                income.date.month == month &&
                income.date.day == day,
          )
          .fold(0, (total, income) => total + income.amount);

      return _ChartData(
        label: '$day日',
        income: incomeTotal,
        expense:
            expenseTotal +
            (day == 1
                ? _activeFixedCostTotalForMonth(DateTime(year, month))
                : 0),
      );
    });
  }

  List<_ChartData> _createYearlyData() {
    final int year = widget.selectedMonth.year;

    return List.generate(12, (index) {
      final int month = index + 1;

      final int expenseTotal = widget.expenses
          .where(
            (expense) =>
                expense.date.year == year && expense.date.month == month,
          )
          .fold(0, (total, expense) => total + expense.amount);

      final int incomeTotal = widget.incomeRecords
          .where(
            (income) => income.date.year == year && income.date.month == month,
          )
          .fold(0, (total, income) => total + income.amount);

      return _ChartData(
        label: '$month月',
        income: incomeTotal,
        expense:
            expenseTotal + _activeFixedCostTotalForMonth(DateTime(year, month)),
      );
    });
  }

  List<_ChartData> _createFiveYearData() {
    final int finalYear = widget.selectedMonth.year;
    final int firstYear = finalYear - 4;

    return List.generate(5, (index) {
      final int year = firstYear + index;

      final int expenseTotal = widget.expenses
          .where((expense) => expense.date.year == year)
          .fold(0, (total, expense) => total + expense.amount);

      final int incomeTotal = widget.incomeRecords
          .where((income) => income.date.year == year)
          .fold(0, (total, income) => total + income.amount);

      final int fixedCostTotal = List.generate(12, (monthIndex) {
        return _activeFixedCostTotalForMonth(DateTime(year, monthIndex + 1));
      }).fold(0, (total, amount) => total + amount);

      return _ChartData(
        label: '$year年',
        income: incomeTotal,
        expense: expenseTotal + fixedCostTotal,
      );
    });
  }

  List<_AnnualCategoryData> _createAnnualCategoryData() {
    final int year = widget.selectedMonth.year;
    final Map<String, List<int>> monthlyTotals = {};

    for (final Expense expense in widget.expenses.where(
      (expense) => expense.date.year == year,
    )) {
      final List<int> totals = monthlyTotals.putIfAbsent(
        expense.category,
        () => List<int>.filled(12, 0),
      );

      totals[expense.date.month - 1] += expense.amount;
    }

    for (final FixedCost fixedCost in widget.fixedCosts.where(
      (fixedCost) => fixedCost.isActive,
    )) {
      final List<int> totals = monthlyTotals.putIfAbsent(
        fixedCost.category,
        () => List<int>.filled(12, 0),
      );

      for (int monthIndex = 0; monthIndex < 12; monthIndex++) {
        totals[monthIndex] += fixedCost.amountForMonth(
          DateTime(year, monthIndex + 1),
        );
      }
    }

    final List<_AnnualCategoryData> data = monthlyTotals.entries
        .map((entry) {
          final int annualTotal = entry.value.fold(
            0,
            (total, amount) => total + amount,
          );

          int highestMonthIndex = 0;

          for (int index = 1; index < entry.value.length; index++) {
            if (entry.value[index] > entry.value[highestMonthIndex]) {
              highestMonthIndex = index;
            }
          }

          return _AnnualCategoryData(
            category: entry.key,
            annualTotal: annualTotal,
            monthlyAverage: (annualTotal / 12).round(),
            highestMonth: highestMonthIndex + 1,
            highestMonthAmount: entry.value[highestMonthIndex],
          );
        })
        .where((item) => item.annualTotal > 0)
        .toList();

    data.sort((a, b) => b.annualTotal.compareTo(a.annualTotal));
    return data;
  }

  String _periodTitle() {
    switch (_selectedPeriod) {
      case AnalysisPeriod.oneMonth:
        return DateFormat('yyyy年M月').format(widget.selectedMonth);

      case AnalysisPeriod.oneYear:
        return '${widget.selectedMonth.year}年';

      case AnalysisPeriod.fiveYears:
        return '${widget.selectedMonth.year - 4}年'
            '〜${widget.selectedMonth.year}年';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_ChartData> data = _createChartData();
    final List<_AnnualCategoryData> annualCategoryData =
        _selectedPeriod == AnalysisPeriod.oneYear
        ? _createAnnualCategoryData()
        : const [];

    final int incomeTotal = data.fold(0, (total, item) => total + item.income);

    final int expenseTotal = data.fold(
      0,
      (total, item) => total + item.expense,
    );

    final int balance = incomeTotal - expenseTotal;

    final double highestAmount = data.fold<double>(
      0,
      (highest, item) =>
          max(highest, max(item.income.toDouble(), item.expense.toDouble())),
    );

    final double chartMaximum = highestAmount <= 0
        ? 10000
        : highestAmount * 1.2;

    final List<FlSpot> incomeSpots = data
        .asMap()
        .entries
        .map(
          (entry) =>
              FlSpot(entry.key.toDouble(), entry.value.income.toDouble()),
        )
        .toList();

    final List<FlSpot> expenseSpots = data
        .asMap()
        .entries
        .map(
          (entry) =>
              FlSpot(entry.key.toDouble(), entry.value.expense.toDouble()),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<AnalysisPeriod>(
          segments: const [
            ButtonSegment(value: AnalysisPeriod.oneMonth, label: Text('1か月')),
            ButtonSegment(value: AnalysisPeriod.oneYear, label: Text('1年')),
            ButtonSegment(value: AnalysisPeriod.fiveYears, label: Text('5年')),
          ],
          selected: {_selectedPeriod},
          onSelectionChanged: (selection) {
            setState(() {
              _selectedPeriod = selection.first;
            });
          },
        ),
        const SizedBox(height: 16),
        Text(
          _periodTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '収入',
                amount: incomeTotal,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: '支出',
                amount: expenseTotal,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryCard(
          title: '収支差',
          amount: balance,
          color: balance >= 0 ? Colors.blue : Colors.red,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: Colors.green, label: '収入'),
            const SizedBox(width: 24),
            _Legend(color: Colors.red, label: '支出'),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
            child: SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: chartMaximum,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          final String text;

                          if (value >= 10000) {
                            text = '${(value / 10000).round()}万';
                          } else {
                            text = value.round().toString();
                          }

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: _selectedPeriod == AnalysisPeriod.oneMonth
                            ? 7
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final int index = value.round();

                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              data[index].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_selectedPeriod == AnalysisPeriod.oneYear) ...[
          const SizedBox(height: 24),
          Text(
            '${widget.selectedMonth.year}年　カテゴリ別支出比較',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (annualCategoryData.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('この年の支出記録はありません')),
              ),
            )
          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('カテゴリ')),
                    DataColumn(label: Text('年間合計'), numeric: true),
                    DataColumn(label: Text('月平均'), numeric: true),
                    DataColumn(label: Text('最も多い月')),
                  ],
                  rows: annualCategoryData.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item.category)),
                        DataCell(
                          Text('¥${_moneyFormat.format(item.annualTotal)}'),
                        ),
                        DataCell(
                          Text('¥${_moneyFormat.format(item.monthlyAverage)}'),
                        ),
                        DataCell(
                          Text(
                            '${item.highestMonth}月\n'
                            '¥${_moneyFormat.format(item.highestMonthAmount)}',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          '支出には有効になっている固定費を含みます。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ChartData {
  const _ChartData({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final int income;
  final int expense;
}

class _AnnualCategoryData {
  const _AnnualCategoryData({
    required this.category,
    required this.annualTotal,
    required this.monthlyAverage,
    required this.highestMonth,
    required this.highestMonthAmount,
  });

  final String category;
  final int annualTotal;
  final int monthlyAverage;
  final int highestMonth;
  final int highestMonthAmount;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
        padding: const EdgeInsets.all(16),
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

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
