import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_controller.dart';

class ExpensePieChart extends StatelessWidget {
  final ExpenseController controller;

  const ExpensePieChart({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.expenseData.value == null) {
        return const Center(child: Text('No data available'));
      }

      final filteredExpenses = controller.filteredExpenses;
      if (filteredExpenses.isEmpty) {
        return const Center(
            child: Text('No data available for selected filters'));
      }

      // Group expenses by category
      final categoryTotals = <String, double>{};
      for (final expense in filteredExpenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      // Sort categories by amount (descending)
      final sortedCategories = categoryTotals.keys.toList()
        ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

      // Calculate total amount
      final totalAmount =
          categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

      // Create pie chart sections
      final sections = <PieChartSectionData>[];

      for (int i = 0; i < sortedCategories.length; i++) {
        final category = sortedCategories[i];
        final amount = categoryTotals[category]!;
        final percentage = (amount / totalAmount) * 100;

        sections.add(
          PieChartSectionData(
            color: controller.categoryColors[category] ?? Colors.grey,
            value: amount,
            title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: percentage < 5
                ? _Badge(
                    category: category,
                    size: 12,
                    color: controller.categoryColors[category] ?? Colors.grey,
                  )
                : null,
            badgePositionPercentageOffset: 1.1,
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Handle touch events if needed
                  },
                  enabled: true,
                ),
              ),
            ),
          ),
          // Legend
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Total amount
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Total: ${controller.formatCurrency(totalAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Category legend
                Wrap(
                  spacing: 16.0,
                  runSpacing: 8.0,
                  children: sortedCategories.map((category) {
                    final amount = categoryTotals[category]!;
                    final percentage = (amount / totalAmount) * 100;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: controller.categoryColors[category] ??
                              Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$category: ${controller.formatCurrency(amount)} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// Badge widget for small pie sections
class _Badge extends StatelessWidget {
  final String category;
  final double size;
  final Color color;

  const _Badge({
    required this.category,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}
