import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'data_service.dart';
import 'models/asset_record.dart';
import 'models/expense.dart';
import 'models/fixed_cost.dart';
import 'models/income_record.dart';
import 'screens/analysis_screen.dart';
import 'screens/asset_screen.dart';
import 'screens/category_settings_screen.dart';
import 'screens/fixed_cost_screen.dart';
import 'screens/home_screen.dart';
import 'screens/income_form_screen.dart';
import 'screens/record_screen.dart';

enum FixedCostChangeScope { thisMonth, fromThisMonth, allMonths }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'わが家の家計簿',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DataService _dataService = DataService();
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  int _selectedIndex = 0;
  RecordType _selectedRecordType = RecordType.expense;
  bool _isLoading = true;
  bool _pendingExpenseShortcut = false;
  bool _isExpenseDialogOpen = false;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<Expense> _expenses = [];
  List<IncomeRecord> _incomeRecords = [];
  List<FixedCost> _fixedCosts = [];
  List<AssetRecord> _assets = [];

  Map<String, int> _budgets = {};

  List<String> _expenseCategories = [
    '食費',
    '外食費',
    '日用品',
    '家具・家電製品',
    '医療費',
    '娯楽',
    'おもちゃ代',
    '交通費',
    '旅行',
    '衣服',
    '美容代',
    'ガソリン',
    '税金',
    'その他',
  ];

  List<String> _fixedCostCategories = [
    '奨学金',
    '積立費用',
    '習い事',
    '自動車保険',
    '住宅ローン',
    '保育料',
    '公共料金',
    '保険料',
    'サブスク',
    'ジム',
    '通信費・携帯料金',
    'その他',
  ];

  List<String> _incomeCategories = [
    '夫給与',
    '妻給与',
    '夫ボーナス',
    '妻ボーナス',
    '児童手当',
    '配当金',
    '副業収入',
    '臨時収入',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _listenForShortcutLinks();
    _loadAllData();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _listenForShortcutLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleAppLink);
  }

  void _handleAppLink(Uri uri) {
    final bool isExpenseShortcut =
        uri.scheme == 'myfinance' &&
        (uri.host == 'add-expense' || uri.path == '/add-expense');

    if (!isExpenseShortcut) {
      return;
    }

    if (_isLoading) {
      _pendingExpenseShortcut = true;
      return;
    }

    _openExpenseFromShortcut();
  }

  void _openExpenseFromShortcut() {
    if (!mounted || _isExpenseDialogOpen) {
      return;
    }

    setState(() {
      _selectedRecordType = RecordType.expense;
      _selectedIndex = 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showExpenseDialog();
      }
    });
  }

  String _monthKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  int get _currentBudget {
    return _budgets[_monthKey(_selectedMonth)] ?? 300000;
  }

  List<Expense> get _currentExpenses {
    final List<Expense> result = _expenses.where((expense) {
      return expense.date.year == _selectedMonth.year &&
          expense.date.month == _selectedMonth.month;
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<IncomeRecord> get _currentIncomeRecords {
    final List<IncomeRecord> result = _incomeRecords.where((income) {
      return income.date.year == _selectedMonth.year &&
          income.date.month == _selectedMonth.month;
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  int get _currentIncome {
    return _currentIncomeRecords.fold(
      0,
      (total, income) => total + income.amount,
    );
  }

  Future<void> _loadAllData() async {
    final List<Expense> expenses = await _dataService.loadExpenses();

    final List<IncomeRecord> incomeRecords = await _dataService
        .loadIncomeRecords();

    final List<FixedCost> fixedCosts = await _dataService.loadFixedCosts();

    final List<AssetRecord> assets = await _dataService.loadAssets();

    final Map<String, int> budgets = await _dataService.loadBudgets();

    final List<String> expenseCategories = await _dataService
        .loadExpenseCategories(_expenseCategories);

    final List<String> fixedCostCategories = await _dataService
        .loadFixedCostCategories(_fixedCostCategories);

    final List<String> incomeCategories = await _dataService
        .loadIncomeCategories(_incomeCategories);

    if (!mounted) {
      return;
    }

    setState(() {
      _expenses = expenses;
      _incomeRecords = incomeRecords;
      _fixedCosts = fixedCosts;
      _assets = assets;
      _budgets = budgets;
      _expenseCategories = expenseCategories;
      _fixedCostCategories = fixedCostCategories;
      _incomeCategories = incomeCategories;
      _isLoading = false;
    });

    if (_pendingExpenseShortcut) {
      _pendingExpenseShortcut = false;
      _openExpenseFromShortcut();
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _openExpenseRecords() {
    setState(() {
      _selectedRecordType = RecordType.expense;
      _selectedIndex = 1;
    });
  }

  void _openIncomeRecords() {
    setState(() {
      _selectedRecordType = RecordType.income;
      _selectedIndex = 1;
    });
  }

  void _openFixedCosts() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  Future<void> _showMonthlySettings() async {
    final TextEditingController controller = TextEditingController(
      text: _currentBudget.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('今月の予算'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '予算',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                final int? budget = int.tryParse(controller.text);

                if (budget == null || budget < 0) {
                  return;
                }

                setState(() {
                  _budgets[_monthKey(_selectedMonth)] = budget;
                });

                await _dataService.saveBudgets(_budgets);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExpenseDialog({Expense? existingExpense}) async {
    if (_isExpenseDialogOpen) {
      return;
    }

    _isExpenseDialogOpen = true;

    final TextEditingController amountController = TextEditingController(
      text: existingExpense?.amount.toString() ?? '',
    );

    final TextEditingController memoController = TextEditingController(
      text: existingExpense?.memo ?? '',
    );

    String category = existingExpense?.category ?? _expenseCategories.first;

    DateTime date = existingExpense?.date ?? DateTime.now();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(existingExpense == null ? '支出を追加' : '支出を編集'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '金額',
                          prefixText: '¥',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: '支出カテゴリ',
                          border: OutlineInputBorder(),
                        ),
                        items: _expenseCategories.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('日付'),
                        subtitle: Text(
                          '${date.year}年${date.month}月${date.day}日',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              date = picked;
                            });
                          }
                        },
                      ),
                      TextField(
                        controller: memoController,
                        decoration: const InputDecoration(
                          labelText: 'メモ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final int? amount = int.tryParse(amountController.text);

                      if (amount == null || amount <= 0) {
                        return;
                      }

                      final Expense expense = Expense(
                        id:
                            existingExpense?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        amount: amount,
                        category: category,
                        memo: memoController.text.trim(),
                        date: date,
                      );

                      setState(() {
                        if (existingExpense == null) {
                          _expenses.add(expense);
                        } else {
                          final int index = _expenses.indexWhere(
                            (item) => item.id == existingExpense.id,
                          );

                          if (index >= 0) {
                            _expenses[index] = expense;
                          }
                        }
                      });

                      await _dataService.saveExpenses(_expenses);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: Text(existingExpense == null ? '保存' : '更新'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      _isExpenseDialogOpen = false;
    }
  }

  Future<void> _showIncomeScreen({IncomeRecord? existingIncome}) async {
    final IncomeRecord? income = await Navigator.push<IncomeRecord>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return IncomeFormScreen(
            categories: _incomeCategories,
            existingIncome: existingIncome,
          );
        },
      ),
    );

    if (income == null) {
      return;
    }

    setState(() {
      if (existingIncome == null) {
        _incomeRecords.add(income);
      } else {
        final int index = _incomeRecords.indexWhere(
          (item) => item.id == existingIncome.id,
        );

        if (index >= 0) {
          _incomeRecords[index] = income;
        }
      }
    });

    await _dataService.saveIncomeRecords(_incomeRecords);
  }

  Future<void> _deleteExpense(Expense expense) async {
    setState(() {
      _expenses.removeWhere((item) => item.id == expense.id);
    });

    await _dataService.saveExpenses(_expenses);
  }

  Future<void> _deleteIncome(IncomeRecord income) async {
    setState(() {
      _incomeRecords.removeWhere((item) => item.id == income.id);
    });

    await _dataService.saveIncomeRecords(_incomeRecords);
  }

  Future<void> _showFixedCostDialog({
    FixedCost? existingFixedCost,
    DateTime? targetMonth,
  }) async {
    final DateTime month = DateTime(
      (targetMonth ?? _selectedMonth).year,
      (targetMonth ?? _selectedMonth).month,
    );

    final TextEditingController nameController = TextEditingController(
      text: existingFixedCost?.name ?? '',
    );

    final TextEditingController amountController = TextEditingController(
      text: existingFixedCost?.amountForMonth(month).toString() ?? '',
    );

    String category = existingFixedCost?.category ?? _fixedCostCategories.first;
    FixedCostChangeScope changeScope = FixedCostChangeScope.thisMonth;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingFixedCost == null ? '固定費を追加' : '固定費を編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (existingFixedCost != null) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<FixedCostChangeScope>(
                        initialValue: changeScope,
                        decoration: const InputDecoration(
                          labelText: '金額を変更する範囲',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: FixedCostChangeScope.thisMonth,
                            child: Text('この月だけ変更'),
                          ),
                          DropdownMenuItem(
                            value: FixedCostChangeScope.fromThisMonth,
                            child: Text('この月以降を変更'),
                          ),
                          DropdownMenuItem(
                            value: FixedCostChangeScope.allMonths,
                            child: Text('すべての月を変更'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              changeScope = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '対象：${month.year}年${month.month}月',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '毎月の金額',
                        prefixText: '¥',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '固定費カテゴリ',
                        border: OutlineInputBorder(),
                      ),
                      items: _fixedCostCategories.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            category = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String name = nameController.text.trim();

                    final int? amount = int.tryParse(amountController.text);

                    final bool invalidAmount = existingFixedCost == null
                        ? amount == null || amount <= 0
                        : amount == null || amount < 0;

                    if (name.isEmpty || invalidAmount) {
                      return;
                    }

                    if (existingFixedCost != null &&
                        amount != existingFixedCost.amountForMonth(month)) {
                      final bool confirmed =
                          await showDialog<bool>(
                            context: dialogContext,
                            builder: (confirmationContext) {
                              return AlertDialog(
                                title: const Text('固定費を変更しますか？'),
                                content: Text(
                                  '${month.year}年${month.month}月の'
                                  '${existingFixedCost.name}を変更します。',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(confirmationContext, false);
                                    },
                                    child: const Text('キャンセル'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.pop(confirmationContext, true);
                                    },
                                    child: const Text('変更'),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;

                      if (!confirmed) {
                        return;
                      }
                    }

                    final FixedCost fixedCost;

                    if (existingFixedCost == null) {
                      fixedCost = FixedCost(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        amount: amount,
                        category: category,
                        isActive: true,
                        startMonth: FixedCost.monthKey(month),
                      );
                    } else {
                      FixedCost updated = existingFixedCost.copyWith(
                        name: name,
                        category: category,
                      );

                      if (amount != existingFixedCost.amountForMonth(month)) {
                        switch (changeScope) {
                          case FixedCostChangeScope.thisMonth:
                            updated = updated.withAmountForMonth(month, amount);

                          case FixedCostChangeScope.fromThisMonth:
                            updated = updated.withAmountFromMonth(
                              month,
                              amount,
                            );

                          case FixedCostChangeScope.allMonths:
                            updated = updated.withAmountForAllMonths(amount);
                        }
                      }

                      fixedCost = updated;
                    }

                    setState(() {
                      if (existingFixedCost == null) {
                        _fixedCosts.add(fixedCost);
                      } else {
                        final int index = _fixedCosts.indexWhere(
                          (item) => item.id == existingFixedCost.id,
                        );

                        if (index >= 0) {
                          _fixedCosts[index] = fixedCost;
                        }
                      }
                    });

                    await _dataService.saveFixedCosts(_fixedCosts);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(existingFixedCost == null ? '保存' : '更新'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleFixedCost(FixedCost fixedCost, bool value) async {
    final int index = _fixedCosts.indexWhere((item) => item.id == fixedCost.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _fixedCosts[index] = fixedCost.copyWith(isActive: value);
    });

    await _dataService.saveFixedCosts(_fixedCosts);
  }

  Future<void> _deleteFixedCost(FixedCost fixedCost) async {
    setState(() {
      _fixedCosts.removeWhere((item) => item.id == fixedCost.id);
    });

    await _dataService.saveFixedCosts(_fixedCosts);
  }

  Future<void> _showAssetDialog({AssetRecord? existingAsset}) async {
    final TextEditingController nameController = TextEditingController(
      text: existingAsset?.name ?? '',
    );

    final TextEditingController amountController = TextEditingController(
      text: existingAsset?.amount.toString() ?? '',
    );

    DateTime date = existingAsset?.date ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingAsset == null ? '資産を追加' : '資産を編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '資産名',
                        hintText: '例：NISA・預金',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '資産残高',
                        prefixText: '¥',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('記録日'),
                      subtitle: Text('${date.year}年${date.month}月${date.day}日'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            date = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String name = nameController.text.trim();

                    final int? amount = int.tryParse(amountController.text);

                    if (name.isEmpty || amount == null || amount < 0) {
                      return;
                    }

                    final AssetRecord asset = AssetRecord(
                      id:
                          existingAsset?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      amount: amount,
                      date: date,
                    );

                    setState(() {
                      if (existingAsset == null) {
                        _assets.add(asset);
                      } else {
                        final int index = _assets.indexWhere(
                          (item) => item.id == existingAsset.id,
                        );

                        if (index >= 0) {
                          _assets[index] = asset;
                        }
                      }
                    });

                    await _dataService.saveAssets(_assets);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(existingAsset == null ? '保存' : '更新'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAsset(AssetRecord asset) async {
    setState(() {
      _assets.removeWhere((item) => item.id == asset.id);
    });

    await _dataService.saveAssets(_assets);
  }

  Future<void> _addCategory(CategoryGroup group, String name) async {
    setState(() {
      switch (group) {
        case CategoryGroup.expense:
          _expenseCategories.add(name);

        case CategoryGroup.fixedCost:
          _fixedCostCategories.add(name);

        case CategoryGroup.income:
          _incomeCategories.add(name);
      }
    });

    await _saveCategories(group);
  }

  Future<void> _renameCategory(
    CategoryGroup group,
    String oldName,
    String newName,
  ) async {
    setState(() {
      switch (group) {
        case CategoryGroup.expense:
          final int index = _expenseCategories.indexOf(oldName);

          if (index >= 0) {
            _expenseCategories[index] = newName;
          }

          _expenses = _expenses.map((expense) {
            return expense.category == oldName
                ? expense.copyWith(category: newName)
                : expense;
          }).toList();

        case CategoryGroup.fixedCost:
          final int index = _fixedCostCategories.indexOf(oldName);

          if (index >= 0) {
            _fixedCostCategories[index] = newName;
          }

          _fixedCosts = _fixedCosts.map((fixedCost) {
            return fixedCost.category == oldName
                ? fixedCost.copyWith(category: newName)
                : fixedCost;
          }).toList();

        case CategoryGroup.income:
          final int index = _incomeCategories.indexOf(oldName);

          if (index >= 0) {
            _incomeCategories[index] = newName;
          }

          _incomeRecords = _incomeRecords.map((income) {
            return income.category == oldName
                ? income.copyWith(category: newName)
                : income;
          }).toList();
      }
    });

    await _saveCategories(group);
    await _saveRecordsForGroup(group);
  }

  Future<void> _deleteCategory(CategoryGroup group, String name) async {
    if (name == 'その他') {
      return;
    }

    setState(() {
      switch (group) {
        case CategoryGroup.expense:
          _expenseCategories.remove(name);

          _expenses = _expenses.map((expense) {
            return expense.category == name
                ? expense.copyWith(category: 'その他')
                : expense;
          }).toList();

        case CategoryGroup.fixedCost:
          _fixedCostCategories.remove(name);

          _fixedCosts = _fixedCosts.map((fixedCost) {
            return fixedCost.category == name
                ? fixedCost.copyWith(category: 'その他')
                : fixedCost;
          }).toList();

        case CategoryGroup.income:
          _incomeCategories.remove(name);

          _incomeRecords = _incomeRecords.map((income) {
            return income.category == name
                ? income.copyWith(category: 'その他')
                : income;
          }).toList();
      }
    });

    await _saveCategories(group);
    await _saveRecordsForGroup(group);
  }

  Future<void> _reorderCategories(
    CategoryGroup group,
    List<String> categories,
  ) async {
    setState(() {
      switch (group) {
        case CategoryGroup.expense:
          _expenseCategories = List<String>.from(categories);

        case CategoryGroup.fixedCost:
          _fixedCostCategories = List<String>.from(categories);

        case CategoryGroup.income:
          _incomeCategories = List<String>.from(categories);
      }
    });

    await _saveCategories(group);
  }

  Future<void> _saveCategories(CategoryGroup group) async {
    switch (group) {
      case CategoryGroup.expense:
        await _dataService.saveExpenseCategories(_expenseCategories);

      case CategoryGroup.fixedCost:
        await _dataService.saveFixedCostCategories(_fixedCostCategories);

      case CategoryGroup.income:
        await _dataService.saveIncomeCategories(_incomeCategories);
    }
  }

  Future<void> _saveRecordsForGroup(CategoryGroup group) async {
    switch (group) {
      case CategoryGroup.expense:
        await _dataService.saveExpenses(_expenses);

      case CategoryGroup.fixedCost:
        await _dataService.saveFixedCosts(_fixedCosts);

      case CategoryGroup.income:
        await _dataService.saveIncomeRecords(_incomeRecords);
    }
  }

  Future<void> _openCategorySettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CategorySettingsScreen(
            expenseCategories: _expenseCategories,
            fixedCostCategories: _fixedCostCategories,
            incomeCategories: _incomeCategories,
            onAdd: _addCategory,
            onRename: _renameCategory,
            onDelete: _deleteCategory,
            onReorder: _reorderCategories,
          );
        },
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('今月の予算'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMonthlySettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('カテゴリ設定'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openCategorySettings();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMenu() {
    if (_selectedIndex == 2) {
      _showFixedCostDialog();
      return;
    }

    if (_selectedIndex == 3) {
      _showAssetDialog();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.arrow_upward, color: Colors.white),
                ),
                title: const Text('支出を追加'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showExpenseDialog();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.arrow_downward, color: Colors.white),
                ),
                title: const Text('収入を追加'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showIncomeScreen();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages = [
      HomeScreen(
        selectedMonth: _selectedMonth,
        budget: _currentBudget,
        income: _currentIncome,
        expenses: _currentExpenses,
        fixedCosts: _fixedCosts,
        onPreviousMonth: _previousMonth,
        onNextMonth: _nextMonth,
        onSettings: _showSettingsMenu,
        onBudgetTap: _showMonthlySettings,
        onExpenseTap: _openExpenseRecords,
        onIncomeTap: _openIncomeRecords,
        onFixedCostTap: _openFixedCosts,
      ),
      RecordScreen(
        expenses: _currentExpenses,
        incomeRecords: _currentIncomeRecords,
        initialType: _selectedRecordType,
        onTypeChanged: (type) {
          _selectedRecordType = type;
        },
        onEditExpense: (expense) {
          _showExpenseDialog(existingExpense: expense);
        },
        onDeleteExpense: (expense) {
          _deleteExpense(expense);
        },
        onEditIncome: (income) {
          _showIncomeScreen(existingIncome: income);
        },
        onDeleteIncome: (income) {
          _deleteIncome(income);
        },
      ),
      FixedCostScreen(
        selectedMonth: _selectedMonth,
        fixedCosts: _fixedCosts,
        onPreviousMonth: _previousMonth,
        onNextMonth: _nextMonth,
        onEdit: (fixedCost, month) {
          _showFixedCostDialog(
            existingFixedCost: fixedCost,
            targetMonth: month,
          );
        },
        onDelete: (fixedCost) {
          _deleteFixedCost(fixedCost);
        },
        onToggle: (fixedCost, value) {
          _toggleFixedCost(fixedCost, value);
        },
      ),
      AssetScreen(
        assets: _assets,
        onEdit: (asset) {
          _showAssetDialog(existingAsset: asset);
        },
        onDelete: (asset) {
          _deleteAsset(asset);
        },
      ),
      AnalysisScreen(
        selectedMonth: _selectedMonth,
        expenses: _expenses,
        incomeRecords: _incomeRecords,
        fixedCosts: _fixedCosts,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('わが家の家計簿'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 4
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddMenu,
              icon: const Icon(Icons.add),
              label: Text(
                _selectedIndex == 2
                    ? '固定費を追加'
                    : _selectedIndex == 3
                    ? '資産を追加'
                    : '記録を追加',
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '記録',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '固定費',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: '資産',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: '分析',
          ),
        ],
      ),
    );
  }
}
