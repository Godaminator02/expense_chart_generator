import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';

class ExpenseBarChart extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseBarChart({
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

      // Get daily totals by category
      final dailyTotals =
          controller.expenseData.value!.getDailyTotalsByCategory();

      // Filter based on selected date range and category
      final filteredDailyTotals = <DateTime, Map<String, double>>{};
      for (final entry in dailyTotals.entries) {
        final date = entry.key;

        // Apply date filter
        if (controller.startDate.value != null &&
            date.isBefore(controller.startDate.value!)) {
          continue;
        }

        if (controller.endDate.value != null &&
            date.isAfter(controller.endDate.value!)) {
          continue;
        }

        // Apply category filter
        if (controller.selectedCategory.value.isNotEmpty) {
          final categoryMap = <String, double>{};
          if (entry.value.containsKey(controller.selectedCategory.value)) {
            categoryMap[controller.selectedCategory.value] =
                entry.value[controller.selectedCategory.value]!;
          }

          if (categoryMap.isNotEmpty) {
            filteredDailyTotals[date] = categoryMap;
          }
        } else {
          filteredDailyTotals[date] = entry.value;
        }
      }

      if (filteredDailyTotals.isEmpty) {
        return const Center(
            child: Text('No data available for selected filters'));
      }

      // Sort dates
      final sortedDates = filteredDailyTotals.keys.toList()..sort();

      // Limit to a reasonable number of bars (e.g., 15)
      final maxBars = 15;
      List<DateTime> displayDates = sortedDates;

      if (sortedDates.length > maxBars) {
        // Sample dates evenly
        final step = sortedDates.length ~/ maxBars;
        displayDates = [];

        for (int i = 0; i < sortedDates.length; i += step) {
          displayDates.add(sortedDates[i]);

          if (displayDates.length >= maxBars) break;
        }

        // Always include the last date
        if (!displayDates.contains(sortedDates.last)) {
          displayDates.add(sortedDates.last);
        }
      }

      // Get all categories in the filtered data
      final allCategories = <String>{};
      for (final entry in filteredDailyTotals.entries) {
        allCategories.addAll(entry.value.keys);
      }

      final sortedCategories = allCategories.toList()..sort();

      // Create bar groups
      final barGroups = <BarChartGroupData>[];

      for (int i = 0; i < displayDates.length; i++) {
        final date = displayDates[i];
        final categoryValues = filteredDailyTotals[date] ?? {};

        final barRods = <BarChartRodData>[];
        double totalForDay = 0;

        for (final category in sortedCategories) {
          final value = categoryValues[category] ?? 0;
          totalForDay += value;

          if (value > 0) {
            barRods.add(
              BarChartRodData(
                toY: value,
                color: controller.categoryColors[category] ?? Colors.grey,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            );
          }
        }

        // If we have multiple categories, use stacked bars
        if (barRods.length > 1 && controller.selectedCategory.value.isEmpty) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totalForDay,
                  rodStackItems: _createStackItems(barRods, totalForDay),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Otherwise use regular bars
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: barRods,
            ),
          );
        }
      }

      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(barGroups),
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '\$${value.toInt()}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= displayDates.length) {
                            return const SizedBox.shrink();
                          }

                          final date = displayDates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey, width: 1),
                      left: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = displayDates[group.x.toInt()];
                        final formattedDate =
                            DateFormat('MM/dd/yyyy').format(date);

                        if (controller.selectedCategory.value.isNotEmpty) {
                          return BarTooltipItem(
                            '$formattedDate\n${controller.selectedCategory.value}: ${controller.formatCurrency(rod.toY)}',
                            const TextStyle(color: Colors.white),
                          );
                        } else if (rod.rodStackItems.isNotEmpty) {
                          // For stacked bars
                          String tooltip = '$formattedDate\n';
                          double total = 0;

                          for (int i = 0; i < sortedCategories.length; i++) {
                            final category = sortedCategories[i];
                            final value =
                                filteredDailyTotals[date]?[category] ?? 0;

                            if (value > 0) {
                              tooltip +=
                                  '$category: ${controller.formatCurrency(value)}\n';
                              total += value;
                            }
                          }

                          tooltip +=
                              'Total: ${controller.formatCurrency(total)}';
                          return BarTooltipItem(
                            tooltip,
                            const TextStyle(color: Colors.white),
                          );
                        } else {
                          // For single category bars
                          return BarTooltipItem(
                            '$formattedDate\n${controller.formatCurrency(rod.toY)}',
                            const TextStyle(color: Colors.white),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Legend
          if (controller.selectedCategory.value.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 16.0,
                runSpacing: 8.0,
                children: sortedCategories.map((category) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color:
                            controller.categoryColors[category] ?? Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      );
    });
  }

  // Create stack items for stacked bar chart
  List<BarChartRodStackItem> _createStackItems(
      List<BarChartRodData> barRods, double total) {
    final stackItems = <BarChartRodStackItem>[];
    double fromY = 0;

    for (final rod in barRods) {
      stackItems.add(
        BarChartRodStackItem(fromY, fromY + rod.toY, rod.color ?? Colors.grey),
      );
      fromY += rod.toY;
    }

    return stackItems;
  }

  // Calculate maximum Y value for the chart
  double _calculateMaxY(List<BarChartGroupData> barGroups) {
    double maxY = 0;

    for (final group in barGroups) {
      for (final rod in group.barRods) {
        if (rod.toY > maxY) {
          maxY = rod.toY;
        }
      }
    }

    // Add some padding
    return maxY * 1.2;
  }
}
