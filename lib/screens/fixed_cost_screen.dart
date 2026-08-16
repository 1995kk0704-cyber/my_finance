import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fixed_cost.dart';

class FixedCostScreen extends StatelessWidget {
  const FixedCostScreen({
    super.key,
    required this.selectedMonth,
    required this.fixedCosts,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final DateTime selectedMonth;
  final List<FixedCost> fixedCosts;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final void Function(FixedCost fixedCost, DateTime month) onEdit;
  final void Function(FixedCost fixedCost) onDelete;
  final void Function(FixedCost fixedCost, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final NumberFormat format = NumberFormat('#,###');

    final int total = fixedCosts
        .where((fixedCost) => fixedCost.isActive)
        .fold(
          0,
          (sum, fixedCost) => sum + fixedCost.amountForMonth(selectedMonth),
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('この月の固定費合計'),
                  Text(
                    '¥${format.format(total)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: fixedCosts.isEmpty
              ? const _EmptyFixedCosts()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: fixedCosts.length,
                  itemBuilder: (context, index) {
                    final FixedCost fixedCost = fixedCosts[index];
                    final int amount = fixedCost.amountForMonth(selectedMonth);

                    return Card(
                      child: ListTile(
                        onTap: () {
                          onEdit(fixedCost, selectedMonth);
                        },
                        leading: CircleAvatar(
                          child: Icon(
                            fixedCost.isActive ? Icons.check : Icons.pause,
                          ),
                        ),
                        title: Text(fixedCost.name),
                        subtitle: Text(
                          '${fixedCost.category}\n'
                          '¥${format.format(amount)}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Switch(
                              value: fixedCost.isActive,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (value) {
                                onToggle(fixedCost, value);
                              },
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                onDelete(fixedCost);
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyFixedCosts extends StatelessWidget {
  const _EmptyFixedCosts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('固定費はまだ登録されていません', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
