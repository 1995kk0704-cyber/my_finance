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

  int get _activeFixedCostTotal {
    return widget.fixedCosts
        .where((fixedCost) => fixedCost.isActive)
        .fold(0, (total, fixedCost) => total + fixedCost.amount);
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
        expense: expenseTotal + (day == 1 ? _activeFixedCostTotal : 0),
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
        expense: expenseTotal + _activeFixedCostTotal,
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

      return _ChartData(
        label: '$year年',
        income: incomeTotal,
        expense: expenseTotal + (_activeFixedCostTotal * 12),
      );
    });
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
