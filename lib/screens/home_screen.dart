import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/chart_container.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/line_chart_widget.dart';

class HomeScreen extends StatelessWidget {
  final ExpenseController controller = Get.put(ExpenseController());

  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Chart Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.resetFilters,
            tooltip: 'Reset Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // File selection and chart type controls
          _buildControlPanel(),

          // Chart area
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: controller.pickAndParseCSV,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (controller.expenseData.value == null) {
                return _buildInitialState();
              }

              return Column(
                children: [
                  // Filter controls
                  _buildFilterControls(context),

                  // Chart
                  Expanded(
                    child: _buildSelectedChart(),
                  ),

                  // Summary stats
                  _buildSummaryStats(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // Build the initial state when no file is loaded
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.upload_file,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload a CSV file to generate charts',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Center(
            child: const Text(
              'The CSV should contain Date, Category, and Amount columns',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.pickAndParseCSV,
            icon: const Icon(Icons.file_upload),
            label: const Text('Select CSV File'),
          ),
        ],
      ),
    );
  }

  // Build the control panel for file selection and chart type
  Widget _buildControlPanel() {
    return Obx(() {
      final hasData = controller.expenseData.value != null;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // File selection button
            ElevatedButton.icon(
              onPressed: controller.pickAndParseCSV,
              icon: const Icon(Icons.file_upload),
              label: Text(hasData ? 'Change File' : 'Select CSV'),
            ),
            const SizedBox(width: 8),

            // Chart type selection (only show if data is loaded)
            if (hasData)
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'bar',
                      icon: Icon(Icons.bar_chart),
                      label: Text('Bar'),
                    ),
                    ButtonSegment(
                      value: 'pie',
                      icon: Icon(Icons.pie_chart),
                      label: Text('Pie'),
                    ),
                    ButtonSegment(
                      value: 'line',
                      icon: Icon(Icons.show_chart),
                      label: Text('Line'),
                    ),
                  ],
                  selected: {controller.selectedChartType.value},
                  onSelectionChanged: (Set<String> selection) {
                    if (selection.isNotEmpty) {
                      controller.setChartType(selection.first);
                    }
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  // Build the filter controls
  Widget _buildFilterControls(BuildContext context) {
    return Obx(() {
      if (controller.expenseData.value == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category filter
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: controller.selectedCategory.value.isEmpty
                  ? null
                  : controller.selectedCategory.value,
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All Categories'),
                ),
                ...controller.categories
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        )),
              ],
              onChanged: controller.setCategoryFilter,
            ),

            const SizedBox(height: 8),

            // Date range filter
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      controller.startDate.value != null
                          ? 'From: ${DateFormat('MM/dd/yyyy').format(controller.startDate.value!)}'
                          : 'Start Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _selectStartDate(context),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      controller.endDate.value != null
                          ? 'To: ${DateFormat('MM/dd/yyyy').format(controller.endDate.value!)}'
                          : 'End Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _selectEndDate(context),
                  ),
                ),
              ],
            ),

            const Divider(),
          ],
        ),
      );
    });
  }

  // Build the selected chart based on the chart type
  Widget _buildSelectedChart() {
    return Obx(() {
      final chartType = controller.selectedChartType.value;

      Widget chart;
      switch (chartType) {
        case 'bar':
          chart = ExpenseBarChart(controller: controller);
          break;
        case 'pie':
          chart = ExpensePieChart(controller: controller);
          break;
        case 'line':
          chart = ExpenseLineChart(controller: controller);
          break;
        default:
          return const Center(child: Text('Invalid chart type'));
      }

      // Wrap the chart with the ChartContainer for download functionality
      return ChartContainer(
        child: chart,
        chartType: chartType,
      );
    });
  }

  // Build the summary statistics
  Widget _buildSummaryStats() {
    return Obx(() {
      if (controller.expenseData.value == null) {
        return const SizedBox.shrink();
      }

      final totalAmount = controller.filteredExpenses
          .fold(0.0, (sum, expense) => sum + expense.amount);

      final averageAmount = controller.filteredExpenses.isNotEmpty
          ? totalAmount / controller.filteredExpenses.length
          : 0.0;

      return Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey.shade100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spending',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  controller.formatCurrency(totalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Average per Entry',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  controller.formatCurrency(averageAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // Date picker for start date
  Future<void> _selectStartDate(BuildContext context) async {
    if (controller.expenseData.value == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          controller.startDate.value ?? controller.expenseData.value!.minDate,
      firstDate: controller.expenseData.value!.minDate,
      lastDate:
          controller.endDate.value ?? controller.expenseData.value!.maxDate,
    );

    if (picked != null) {
      controller.setDateRange(picked, controller.endDate.value);
    }
  }

  // Date picker for end date
  Future<void> _selectEndDate(BuildContext context) async {
    if (controller.expenseData.value == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          controller.endDate.value ?? controller.expenseData.value!.maxDate,
      firstDate:
          controller.startDate.value ?? controller.expenseData.value!.minDate,
      lastDate: controller.expenseData.value!.maxDate,
    );

    if (picked != null) {
      controller.setDateRange(controller.startDate.value, picked);
    }
  }
}
