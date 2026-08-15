import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/income_record.dart';

enum RecordType { expense, income }

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.expenses,
    required this.incomeRecords,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onEditIncome,
    required this.onDeleteIncome,
  });

  final List<Expense> expenses;
  final List<IncomeRecord> incomeRecords;

  final void Function(Expense expense) onEditExpense;
  final void Function(Expense expense) onDeleteExpense;

  final void Function(IncomeRecord income) onEditIncome;
  final void Function(IncomeRecord income) onDeleteIncome;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  RecordType _selectedType = RecordType.expense;

  final NumberFormat _moneyFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<RecordType>(
            segments: const [
              ButtonSegment(
                value: RecordType.expense,
                icon: Icon(Icons.arrow_upward),
                label: Text('支出'),
              ),
              ButtonSegment(
                value: RecordType.income,
                icon: Icon(Icons.arrow_downward),
                label: Text('収入'),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedType = selection.first;
              });
            },
          ),
        ),
        Expanded(
          child: _selectedType == RecordType.expense
              ? _buildExpenseList()
              : _buildIncomeList(),
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    if (widget.expenses.isEmpty) {
      return const _EmptyRecord(
        icon: Icons.receipt_long,
        message: 'この月の支出記録はありません',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: widget.expenses.length,
      itemBuilder: (context, index) {
        final Expense expense = widget.expenses[index];

        return Dismissible(
          key: ValueKey('expense-${expense.id}'),
          direction: DismissDirection.endToStart,
          background: _buildDeleteBackground(),
          confirmDismiss: (_) {
            return _confirmDelete(
              '${expense.category}　'
              '¥${_moneyFormat.format(expense.amount)}',
            );
          },
          onDismissed: (_) {
            widget.onDeleteExpense(expense);
          },
          child: Card(
            child: ListTile(
              onTap: () {
                widget.onEditExpense(expense);
              },
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.arrow_upward, color: Colors.white),
              ),
              title: Text(expense.category),
              subtitle: Text(
                '${DateFormat('yyyy年M月d日').format(expense.date)}\n'
                '${expense.memo.isEmpty ? 'メモなし' : expense.memo}',
              ),
              isThreeLine: true,
              trailing: Text(
                '−¥${_moneyFormat.format(expense.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomeList() {
    if (widget.incomeRecords.isEmpty) {
      return const _EmptyRecord(
        icon: Icons.payments,
        message: 'この月の収入記録はありません',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: widget.incomeRecords.length,
      itemBuilder: (context, index) {
        final IncomeRecord income = widget.incomeRecords[index];

        return Dismissible(
          key: ValueKey('income-${income.id}'),
          direction: DismissDirection.endToStart,
          background: _buildDeleteBackground(),
          confirmDismiss: (_) {
            return _confirmDelete(
              '${income.category}　'
              '¥${_moneyFormat.format(income.amount)}',
            );
          },
          onDismissed: (_) {
            widget.onDeleteIncome(income);
          },
          child: Card(
            child: ListTile(
              onTap: () {
                widget.onEditIncome(income);
              },
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.arrow_downward, color: Colors.white),
              ),
              title: Text(income.category),
              subtitle: Text(
                '${DateFormat('yyyy年M月d日').format(income.date)}\n'
                '${income.memo.isEmpty ? 'メモなし' : income.memo}',
              ),
              isThreeLine: true,
              trailing: Text(
                '＋¥${_moneyFormat.format(income.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Colors.white),
          Text('削除', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String recordName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('記録を削除しますか？'),
              content: Text(recordName),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('削除'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _EmptyRecord extends StatelessWidget {
  const _EmptyRecord({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
