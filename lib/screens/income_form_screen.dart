import 'package:flutter/material.dart';

import '../models/income_record.dart';

class IncomeFormScreen extends StatefulWidget {
  const IncomeFormScreen({
    super.key,
    required this.categories,
    this.existingIncome,
  });

  final List<String> categories;
  final IncomeRecord? existingIncome;

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;

  late String _selectedCategory;
  late DateTime _selectedDate;

  bool get _isEditing => widget.existingIncome != null;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: widget.existingIncome?.amount.toString() ?? '',
    );

    _memoController = TextEditingController(
      text: widget.existingIncome?.memo ?? '',
    );

    _selectedCategory =
        widget.existingIncome?.category ?? widget.categories.first;

    _selectedDate = widget.existingIncome?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  void _save() {
    final int? amount = int.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正しい金額を入力してください')));

      return;
    }

    final IncomeRecord income = IncomeRecord(
      id:
          widget.existingIncome?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      category: _selectedCategory,
      memo: _memoController.text.trim(),
      date: _selectedDate,
    );

    Navigator.pop(context, income);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '収入を編集' : '収入を追加')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '金額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '収入カテゴリ',
              border: OutlineInputBorder(),
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              onTap: _selectDate,
              leading: const Icon(Icons.calendar_today),
              title: const Text('日付'),
              subtitle: Text(
                '${_selectedDate.year}年'
                '${_selectedDate.month}月'
                '${_selectedDate.day}日',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'メモ',
              hintText: '例：8月分給与',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(_isEditing ? '更新する' : '登録する'),
          ),
        ],
      ),
    );
  }
}
