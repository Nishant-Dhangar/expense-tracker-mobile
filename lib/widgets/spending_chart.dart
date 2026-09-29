import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingChart extends StatelessWidget {
  final Map<String, double> spending;

  const SpendingChart({
    super.key,
    required this.spending,
  });

  static const List<Color> _categoryColors = [
    Color(0xFF5B8DEF),
    Color(0xFF7B61FF),
    Color(0xFFFFA726),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
  ];

  @override
  Widget build(BuildContext context) {
    if (spending.isEmpty) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.15),
      ),
    ),
    child: Column(
      children: [
        Icon(
          Icons.pie_chart_outline_rounded,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          'No expenses this month',
          style: TextStyle(
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.60),
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

    final entries = spending.entries.toList();

    final total = spending.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );

    final sections = entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      return PieChartSectionData(
        value: entry.value,
        color: _categoryColors[index % _categoryColors.length],
        title: '',
        radius: 58,
      );
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
  color: Theme.of(context).cardColor,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(
    color: Theme.of(context)
        .dividerColor
        .withValues(alpha: 0.15),
  ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending This Month',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 62,
                    sectionsSpace: 4,
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
  'Total',
  style: TextStyle(
    color: Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.60),
    fontSize: 13,
  ),
),
                    const SizedBox(height: 4),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          ...entries.asMap().entries.map(
            (item) {
              final index = item.key;
              final entry = item.value;

              final percentage =
                  (entry.value / total * 100)
                      .toStringAsFixed(1);

              final color =
                  _categoryColors[index % _categoryColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 48,
                      child: Text(
                        '$percentage%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
  color: Theme.of(context)
      .textTheme
      .bodyMedium
      ?.color
      ?.withValues(alpha: 0.60),
  fontSize: 12,
),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}