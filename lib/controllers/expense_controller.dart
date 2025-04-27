import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../utils/sample_data_loader.dart';

class ExpenseController extends GetxController {
  // Observable variables
  final Rx<ExpenseData?> expenseData = Rx<ExpenseData?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedCategory = ''.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString selectedChartType = 'bar'.obs; // 'bar', 'pie', 'line'

  // Category colors map
  final RxMap<String, Color> categoryColors = <String, Color>{}.obs;

  // Get filtered expenses based on selected filters
  List<Expense> get filteredExpenses {
    if (expenseData.value == null) return [];

    return expenseData.value!.getFilteredExpenses(
      category: selectedCategory.value.isEmpty ? null : selectedCategory.value,
      startDate: startDate.value,
      endDate: endDate.value,
    );
  }

  // Get available categories
  List<String> get categories {
    if (expenseData.value == null) return [];
    return expenseData.value!.categories.toList()..sort();
  }

  // Get formatted currency
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Get formatted date
  String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Pick and parse CSV file
  Future<void> pickAndParseCSV() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        isLoading.value = false;
        return;
      }

      // Get file path
      final file = File(result.files.single.path!);

      // Read file content
      final content = await file.readAsString();
      print(
          'CSV content: ${content.substring(0, min(200, content.length))}...');

      // Parse CSV
      List<List<dynamic>> rowsAsListOfValues = [];

      // Directly use manual parsing for simplicity and reliability
      print('Using manual CSV parsing...');
      final lines = content.split('\n');
      rowsAsListOfValues = [];

      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          final values = line.split(',').map((v) => v.trim()).toList();
          if (values.isNotEmpty) {
            rowsAsListOfValues.add(values);
            print('Manually parsed row: $values');
          }
        }
      }

      print('After manual parsing, found ${rowsAsListOfValues.length} rows');

      // Check if file has header
      bool hasHeader = true;

      // If first row contains date, category, amount headers, skip it
      if (rowsAsListOfValues.isNotEmpty &&
          rowsAsListOfValues[0].length >= 3 &&
          (rowsAsListOfValues[0][0].toString().toLowerCase().contains('date') ||
              rowsAsListOfValues[0][1]
                  .toString()
                  .toLowerCase()
                  .contains('category') ||
              rowsAsListOfValues[0][2]
                  .toString()
                  .toLowerCase()
                  .contains('amount'))) {
        hasHeader = true;
      }

      // Parse expenses
      final expenses = <Expense>[];
      final errors = <String>[];

      for (int i = hasHeader ? 1 : 0; i < rowsAsListOfValues.length; i++) {
        final row = rowsAsListOfValues[i];

        // Skip empty rows or rows with insufficient columns
        if (row.length < 3 ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        try {
          // Print row data for debugging
          print('Processing row $i: ${row.join(', ')}');

          final expense = Expense.fromCsvRow(row);
          expenses.add(expense);
          print('Successfully parsed row $i: $expense');
        } catch (e) {
          // Skip invalid rows but continue processing
          final errorMsg = 'Error parsing row $i: $e';
          print(errorMsg);
          errors.add(errorMsg);
        }
      }

      if (expenses.isEmpty) {
        final errorMsg = 'No valid expense data found in the CSV file.\n'
            'Errors encountered: ${errors.join('\n')}';
        print('All rows failed to parse. Errors: $errors');
        errorMessage.value = errorMsg;
        isLoading.value = false;
        return;
      }

      // Create expense data
      expenseData.value = ExpenseData.fromExpenses(expenses);

      // Generate colors for categories
      _generateCategoryColors();

      // Reset filters
      selectedCategory.value = '';
      startDate.value = expenseData.value!.minDate;
      endDate.value = expenseData.value!.maxDate;
    } catch (e) {
      errorMessage.value = 'Error processing CSV file: ${e.toString()}';
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Generate colors for categories
  void _generateCategoryColors() {
    if (expenseData.value == null) return;

    final colors = <String, Color>{};
    final baseColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    int colorIndex = 0;
    for (final category in expenseData.value!.categories) {
      // Use base colors and create variations if we have more categories than colors
      final baseColor = baseColors[colorIndex % baseColors.length];

      // Create variations by adjusting shade
      final shade = 100 * ((colorIndex ~/ baseColors.length) + 1);
      final color = colorIndex < baseColors.length
          ? baseColor
          : baseColor.withOpacity(0.5 + (shade / 1000));

      colors[category] = color;
      colorIndex++;
    }

    categoryColors.value = colors;
  }

  // Set chart type
  void setChartType(String type) {
    selectedChartType.value = type;
  }

  // Set category filter
  void setCategoryFilter(String? category) {
    selectedCategory.value = category ?? '';
  }

  // Set date range filter
  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
  }

  // Reset all filters
  void resetFilters() {
    if (expenseData.value == null) return;

    selectedCategory.value = '';
    startDate.value = expenseData.value!.minDate;
    endDate.value = expenseData.value!.maxDate;
  }

  // Load sample data
  Future<void> loadSampleData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load sample data from assets
      final expenses = await SampleDataLoader.loadSampleData();

      if (expenses.isEmpty) {
        errorMessage.value =
            'No sample data found or error loading sample data.';
        isLoading.value = false;
        return;
      }

      // Create expense data
      expenseData.value = ExpenseData.fromExpenses(expenses);

      // Generate colors for categories
      _generateCategoryColors();

      // Reset filters
      selectedCategory.value = '';
      startDate.value = expenseData.value!.minDate;
      endDate.value = expenseData.value!.maxDate;

      // Show success message
      Get.snackbar(
        'Sample Data Loaded',
        'Sample expense data has been loaded successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.7),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      errorMessage.value = 'Error loading sample data: ${e.toString()}';
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
