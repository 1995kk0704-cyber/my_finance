import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/asset_record.dart';

class AssetScreen extends StatelessWidget {
  const AssetScreen({
    super.key,
    required this.assets,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AssetRecord> assets;
  final void Function(AssetRecord asset) onEdit;
  final void Function(AssetRecord asset) onDelete;

  @override
  Widget build(BuildContext context) {
    final NumberFormat format = NumberFormat('#,###');

    final List<AssetRecord> sortedAssets = [...assets]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedAssets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('資産記録はまだありません', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    final List<FlSpot> spots = sortedAssets
        .asMap()
        .entries
        .map(
          (entry) =>
              FlSpot(entry.key.toDouble(), entry.value.amount.toDouble()),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('最新の資産残高'),
                const SizedBox(height: 8),
                Text(
                  '¥${format.format(sortedAssets.last.amount)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '資産推移',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
            child: SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.greenAccent.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '資産履歴',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...sortedAssets.reversed.map(
          (asset) => Card(
            child: ListTile(
              onTap: () {
                onEdit(asset);
              },
              leading: const CircleAvatar(child: Icon(Icons.savings)),
              title: Text(asset.name),
              subtitle: Text(DateFormat('yyyy年M月d日').format(asset.date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¥${format.format(asset.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      onDelete(asset);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
