import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/expense_model.dart';
import 'package:csv/csv.dart';

class SampleDataLoader {
  /// Loads sample expense data from the assets folder
  static Future<List<Expense>> loadSampleData() async {
    try {
      // Load the CSV file from assets
      final String csvString =
          await rootBundle.loadString('assets/sample_expenses.csv');

      print(
          'Sample CSV content loaded: ${csvString.substring(0, min(100, csvString.length))}...');

      // Parse the CSV data using manual parsing for consistency
      print('Using manual CSV parsing...');
      final lines = csvString.split('\n');
      final List<List<dynamic>> csvData = [];

      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          final values = line.split(',').map((v) => v.trim()).toList();
          if (values.isNotEmpty) {
            csvData.add(values);
            print('Manually parsed row: $values');
          }
        }
      }

      print('After manual parsing, found ${csvData.length} rows');

      // Skip the header row and convert to Expense objects
      final expenses = <Expense>[];
      final errors = <String>[];

      // Check if file has header
      bool hasHeader = true;

      // If first row contains date, category, amount headers, skip it
      if (csvData.isNotEmpty &&
          csvData[0].length >= 3 &&
          (csvData[0][0].toString().toLowerCase().contains('date') ||
              csvData[0][1].toString().toLowerCase().contains('category') ||
              csvData[0][2].toString().toLowerCase().contains('amount'))) {
        hasHeader = true;
      }

      for (int i = hasHeader ? 1 : 0; i < csvData.length; i++) {
        try {
          print('Processing row $i: ${csvData[i].join(', ')}');
          final expense = Expense.fromCsvRow(csvData[i]);
          expenses.add(expense);
          print('Successfully parsed row $i: $expense');
        } catch (e) {
          final errorMsg = 'Error parsing row $i: $e';
          print(errorMsg);
          errors.add(errorMsg);
        }
      }

      if (expenses.isEmpty && errors.isNotEmpty) {
        print('All rows failed to parse. Errors: $errors');
      } else {
        print('Successfully parsed ${expenses.length} expense entries');
      }

      return expenses;
    } catch (e) {
      print('Error loading sample data: $e');
      return [];
    }
  }
}
