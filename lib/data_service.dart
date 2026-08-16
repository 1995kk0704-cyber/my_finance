import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/asset_record.dart';
import 'models/expense.dart';
import 'models/fixed_cost.dart';
import 'models/income_record.dart';

class DataService {
  static const String _expensesKey = 'expenses';
  static const String _incomeRecordsKey = 'income_records';
  static const String _fixedCostsKey = 'fixed_costs';
  static const String _assetsKey = 'assets';
  static const String _budgetsKey = 'budgets';

  static const String _expenseCategoriesKey = 'expense_categories';

  static const String _fixedCostCategoriesKey = 'fixed_cost_categories';

  static const String _incomeCategoriesKey = 'income_categories';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<Expense>> loadExpenses() async {
    final List<Map<String, dynamic>> data = await _loadList(_expensesKey);

    return data.map(Expense.fromMap).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    await _saveList(
      _expensesKey,
      expenses.map((expense) => expense.toMap()).toList(),
    );
  }

  Future<List<IncomeRecord>> loadIncomeRecords() async {
    final List<Map<String, dynamic>> data = await _loadList(_incomeRecordsKey);

    return data.map(IncomeRecord.fromMap).toList();
  }

  Future<void> saveIncomeRecords(List<IncomeRecord> incomeRecords) async {
    await _saveList(
      _incomeRecordsKey,
      incomeRecords.map((income) => income.toMap()).toList(),
    );
  }

  Future<List<FixedCost>> loadFixedCosts() async {
    final List<Map<String, dynamic>> data = await _loadList(_fixedCostsKey);

    return data.map(FixedCost.fromMap).toList();
  }

  Future<void> saveFixedCosts(List<FixedCost> fixedCosts) async {
    await _saveList(
      _fixedCostsKey,
      fixedCosts.map((fixedCost) => fixedCost.toMap()).toList(),
    );
  }

  Future<List<AssetRecord>> loadAssets() async {
    final List<Map<String, dynamic>> data = await _loadList(_assetsKey);

    return data.map(AssetRecord.fromMap).toList();
  }

  Future<void> saveAssets(List<AssetRecord> assets) async {
    await _saveList(_assetsKey, assets.map((asset) => asset.toMap()).toList());
  }

  Future<Map<String, int>> loadBudgets() async {
    return _loadIntMap(_budgetsKey);
  }

  Future<void> saveBudgets(Map<String, int> budgets) async {
    await _saveIntMap(_budgetsKey, budgets);
  }

  Future<List<String>> loadExpenseCategories(
    List<String> defaultCategories,
  ) async {
    return _loadCategories(_expenseCategoriesKey, defaultCategories);
  }

  Future<void> saveExpenseCategories(List<String> categories) async {
    await _preferences.setStringList(_expenseCategoriesKey, categories);
  }

  Future<List<String>> loadFixedCostCategories(
    List<String> defaultCategories,
  ) async {
    return _loadCategories(_fixedCostCategoriesKey, defaultCategories);
  }

  Future<void> saveFixedCostCategories(List<String> categories) async {
    await _preferences.setStringList(_fixedCostCategoriesKey, categories);
  }

  Future<List<String>> loadIncomeCategories(
    List<String> defaultCategories,
  ) async {
    return _loadCategories(_incomeCategoriesKey, defaultCategories);
  }

  Future<void> saveIncomeCategories(List<String> categories) async {
    await _preferences.setStringList(_incomeCategoriesKey, categories);
  }

  Future<List<String>> _loadCategories(
    String key,
    List<String> defaultCategories,
  ) async {
    final List<String>? saved = await _preferences.getStringList(key);

    if (saved == null || saved.isEmpty) {
      return List<String>.from(defaultCategories);
    }

    return saved;
  }

  Future<List<Map<String, dynamic>>> _loadList(String key) async {
    final String? savedText = await _preferences.getString(key);

    if (savedText == null || savedText.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(savedText);

      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> data) async {
    await _preferences.setString(key, jsonEncode(data));
  }

  Future<Map<String, int>> _loadIntMap(String key) async {
    final String? savedText = await _preferences.getString(key);

    if (savedText == null || savedText.isEmpty) {
      return {};
    }

    try {
      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
        jsonDecode(savedText) as Map,
      );

      return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveIntMap(String key, Map<String, int> data) async {
    await _preferences.setString(key, jsonEncode(data));
  }
}
