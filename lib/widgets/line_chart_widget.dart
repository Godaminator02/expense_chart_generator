import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';

class ExpenseLineChart extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseLineChart({
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

      // Group expenses by date
      final Map<DateTime, double> dailyTotals = {};

      for (final expense in filteredExpenses) {
        final date =
            DateTime(expense.date.year, expense.date.month, expense.date.day);
        dailyTotals[date] = (dailyTotals[date] ?? 0) + expense.amount;
      }

      // Sort dates
      final sortedDates = dailyTotals.keys.toList()..sort();

      if (sortedDates.isEmpty) {
        return const Center(
            child: Text('No data available for selected filters'));
      }

      // Create line chart spots
      final spots = <FlSpot>[];

      // Calculate x-axis interval (days between min and max date)
      final minDate = sortedDates.first;
      final maxDate = sortedDates.last;
      final totalDays = maxDate.difference(minDate).inDays;

      // Map each date to an x-axis position
      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final daysDifference = date.difference(minDate).inDays;

        // X position is the day difference from min date
        final xPosition = daysDifference.toDouble();
        final yPosition = dailyTotals[date]!;

        spots.add(FlSpot(xPosition, yPosition));
      }

      // Calculate 7-day moving average if we have enough data
      final movingAverageSpots = <FlSpot>[];

      if (sortedDates.length >= 7) {
        for (int i = 6; i < sortedDates.length; i++) {
          double sum = 0;
          for (int j = i - 6; j <= i; j++) {
            sum += dailyTotals[sortedDates[j]]!;
          }

          final average = sum / 7;
          final date = sortedDates[i];
          final daysDifference = date.difference(minDate).inDays;

          movingAverageSpots.add(FlSpot(daysDifference.toDouble(), average));
        }
      }

      // Find max Y value for scaling
      double maxY = 0;
      for (final amount in dailyTotals.values) {
        if (amount > maxY) {
          maxY = amount;
        }
      }

      // Add some padding to max Y
      maxY = maxY * 1.2;

      // Create date formatter for x-axis labels
      final dateFormatter = DateFormat('MM/dd');

      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    // Daily expenses line
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    // 7-day moving average line (if available)
                    if (movingAverageSpots.isNotEmpty)
                      LineChartBarData(
                        spots: movingAverageSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5], // Dashed line
                      ),
                  ],
                  minY: 0,
                  maxY: maxY,
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
                          // Show a reasonable number of date labels
                          final daysToShow = totalDays <= 30 ? 5 : 10;
                          final interval = totalDays / daysToShow;

                          if (value % interval > 0.1 &&
                              value != 0 &&
                              value != totalDays.toDouble()) {
                            return const SizedBox.shrink();
                          }

                          final date =
                              minDate.add(Duration(days: value.toInt()));

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dateFormatter.format(date),
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
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date =
                              minDate.add(Duration(days: spot.x.toInt()));
                          final formattedDate =
                              DateFormat('MM/dd/yyyy').format(date);

                          final isMovingAverage = spot.barIndex == 1;
                          final label = isMovingAverage
                              ? '7-day Avg: ${controller.formatCurrency(spot.y)}'
                              : 'Amount: ${controller.formatCurrency(spot.y)}';

                          return LineTooltipItem(
                            '$formattedDate\n$label',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Legend
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Daily expenses legend
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Daily Expenses',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Moving average legend (if available)
                if (movingAverageSpots.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '7-day Moving Average',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Stats
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Text(
                  'Total: ${controller.formatCurrency(dailyTotals.values.fold(0.0, (sum, amount) => sum + amount))}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Average Daily: ${controller.formatCurrency(dailyTotals.values.fold(0.0, (sum, amount) => sum + amount) / dailyTotals.length)}',
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
