import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fixed_cost.dart';

class FixedCostScreen extends StatelessWidget {
  const FixedCostScreen({
    super.key,
    required this.fixedCosts,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final List<FixedCost> fixedCosts;
  final void Function(FixedCost fixedCost) onEdit;
  final void Function(FixedCost fixedCost) onDelete;
  final void Function(FixedCost fixedCost, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final NumberFormat format = NumberFormat('#,###');

    if (fixedCosts.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fixedCosts.length,
      itemBuilder: (context, index) {
        final FixedCost fixedCost = fixedCosts[index];

        return Card(
          child: ListTile(
            onTap: () {
              onEdit(fixedCost);
            },
            leading: CircleAvatar(
              child: Icon(fixedCost.isActive ? Icons.check : Icons.pause),
            ),
            title: Text(fixedCost.name),
            subtitle: Text(fixedCost.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¥${format.format(fixedCost.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: fixedCost.isActive,
                  onChanged: (value) {
                    onToggle(fixedCost, value);
                  },
                ),
                IconButton(
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
    );
  }
}
