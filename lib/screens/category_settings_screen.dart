import 'package:flutter/material.dart';

enum CategoryGroup { expense, fixedCost, income }

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({
    super.key,
    required this.expenseCategories,
    required this.fixedCostCategories,
    required this.incomeCategories,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.onReorder,
  });

  final List<String> expenseCategories;
  final List<String> fixedCostCategories;
  final List<String> incomeCategories;

  final Future<void> Function(CategoryGroup group, String name) onAdd;

  final Future<void> Function(
    CategoryGroup group,
    String oldName,
    String newName,
  )
  onRename;

  final Future<void> Function(CategoryGroup group, String name) onDelete;

  final Future<void> Function(CategoryGroup group, List<String> categories)
  onReorder;

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  late List<String> _expenseCategories;
  late List<String> _fixedCostCategories;
  late List<String> _incomeCategories;

  @override
  void initState() {
    super.initState();

    _expenseCategories = List<String>.from(widget.expenseCategories);

    _fixedCostCategories = List<String>.from(widget.fixedCostCategories);

    _incomeCategories = List<String>.from(widget.incomeCategories);
  }

  List<String> _categoriesFor(CategoryGroup group) {
    switch (group) {
      case CategoryGroup.expense:
        return _expenseCategories;

      case CategoryGroup.fixedCost:
        return _fixedCostCategories;

      case CategoryGroup.income:
        return _incomeCategories;
    }
  }

  String _groupName(CategoryGroup group) {
    switch (group) {
      case CategoryGroup.expense:
        return '支出';

      case CategoryGroup.fixedCost:
        return '固定費';

      case CategoryGroup.income:
        return '収入';
    }
  }

  Future<void> _addCategory(CategoryGroup group) async {
    final List<String> categories = _categoriesFor(group);

    final TextEditingController controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${_groupName(group)}カテゴリを追加'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'カテゴリ名',
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
                final String name = controller.text.trim();

                if (name.isEmpty) {
                  return;
                }

                if (categories.contains(name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('同じカテゴリがすでにあります')),
                  );
                  return;
                }

                await widget.onAdd(group, name);

                if (!mounted) {
                  return;
                }

                setState(() {
                  categories.add(name);
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameCategory(CategoryGroup group, String oldName) async {
    final List<String> categories = _categoriesFor(group);

    final TextEditingController controller = TextEditingController(
      text: oldName,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('カテゴリ名を変更'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '新しいカテゴリ名',
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
                final String newName = controller.text.trim();

                if (newName.isEmpty) {
                  return;
                }

                if (newName != oldName && categories.contains(newName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('同じカテゴリがすでにあります')),
                  );
                  return;
                }

                await widget.onRename(group, oldName, newName);

                if (!mounted) {
                  return;
                }

                final int index = categories.indexOf(oldName);

                if (index >= 0) {
                  setState(() {
                    categories[index] = newName;
                  });
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('変更'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(CategoryGroup group, String category) async {
    if (category == 'その他') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('「その他」は削除できません')));
      return;
    }

    final bool shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('カテゴリを削除しますか？'),
              content: Text(
                '「$category」を削除します。\n'
                '過去の記録は「その他」へ移動します。',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('削除'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    await widget.onDelete(group, category);

    if (!mounted) {
      return;
    }

    setState(() {
      _categoriesFor(group).remove(category);
    });
  }

  Future<void> _reorderCategory(
    CategoryGroup group,
    int oldIndex,
    int newIndex,
  ) async {
    final List<String> categories = _categoriesFor(group);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    setState(() {
      final String moved = categories.removeAt(oldIndex);

      categories.insert(newIndex, moved);
    });

    await widget.onReorder(group, List<String>.from(categories));
  }

  Widget _buildCategoryList(CategoryGroup group) {
    final List<String> categories = _categoriesFor(group);

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              _reorderCategory(group, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final String category = categories[index];

              return Card(
                key: ValueKey('${group.name}-$category'),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(category),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameCategory(group, category);
                      }

                      if (value == 'delete') {
                        _deleteCategory(group, category);
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 12),
                              Text('名前を変更'),
                            ],
                          ),
                        ),
                        if (category != 'その他')
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 12),
                                Text('削除', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ];
                    },
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {
              _addCategory(group);
            },
            icon: const Icon(Icons.add),
            label: Text('${_groupName(group)}カテゴリを追加'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('カテゴリ設定'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '支出'),
              Tab(text: '固定費'),
              Tab(text: '収入'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategoryList(CategoryGroup.expense),
            _buildCategoryList(CategoryGroup.fixedCost),
            _buildCategoryList(CategoryGroup.income),
          ],
        ),
      ),
    );
  }
}
