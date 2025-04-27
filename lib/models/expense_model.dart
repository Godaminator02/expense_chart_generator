import 'package:intl/intl.dart';

class Expense {
  final DateTime date;
  final String category;
  final double amount;

  Expense({
    required this.date,
    required this.category,
    required this.amount,
  });

  factory Expense.fromCsvRow(List<dynamic> row) {
    try {
      print('Parsing row: $row');

      // Try to parse date with different formats
      DateTime? parsedDate;
      final dateStr = row[0].toString().trim();
      print('Date string: "$dateStr"');

      // Try common date formats
      final formats = [
        'yyyy-MM-dd',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'yyyy/MM/dd',
        'MM-dd-yyyy',
        'dd-MM-yyyy',
        'dd/MM/yy', // Format for DD/MM/YY (e.g., 29/03/25)
      ];

      print('Trying to parse date with formats: $formats');

      for (final format in formats) {
        try {
          print('Trying format: $format');
          parsedDate = DateFormat(format).parse(dateStr);
          print('Successfully parsed date with format $format: $parsedDate');
          break;
        } catch (e) {
          print('Failed to parse with format $format: $e');
          // Continue to next format
        }
      }

      if (parsedDate == null) {
        throw Exception('Unable to parse date: $dateStr');
      }

      final category = row[1].toString().trim();
      print('Category: "$category"');

      final amountStr = row[2].toString().replaceAll(',', '').trim();
      print('Amount string: "$amountStr"');

      final amount = double.tryParse(amountStr);
      if (amount == null) {
        throw Exception('Unable to parse amount: $amountStr');
      }
      print('Parsed amount: $amount');

      return Expense(
        date: parsedDate,
        category: category,
        amount: amount,
      );
    } catch (e) {
      print('Error in fromCsvRow: $e');
      throw Exception('Error parsing CSV row: $e');
    }
  }

  @override
  String toString() =>
      'Expense(date: $date, category: $category, amount: $amount)';
}

class ExpenseData {
  final List<Expense> expenses;
  final Set<String> categories;
  final DateTime minDate;
  final DateTime maxDate;
  final double totalAmount;
  final double averageDailyAmount;

  ExpenseData({
    required this.expenses,
    required this.categories,
    required this.minDate,
    required this.maxDate,
    required this.totalAmount,
    required this.averageDailyAmount,
  });

  factory ExpenseData.fromExpenses(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return ExpenseData(
        expenses: [],
        categories: {},
        minDate: DateTime.now(),
        maxDate: DateTime.now(),
        totalAmount: 0,
        averageDailyAmount: 0,
      );
    }

    // Sort expenses by date
    expenses.sort((a, b) => a.date.compareTo(b.date));

    // Extract categories
    final categories = expenses.map((e) => e.category).toSet();

    // Calculate date range
    final minDate = expenses.first.date;
    final maxDate = expenses.last.date;

    // Calculate total amount
    final totalAmount =
        expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    // Calculate average daily amount
    final daysDifference = maxDate.difference(minDate).inDays + 1;
    final averageDailyAmount = totalAmount / daysDifference;

    return ExpenseData(
      expenses: expenses,
      categories: categories,
      minDate: minDate,
      maxDate: maxDate,
      totalAmount: totalAmount,
      averageDailyAmount: averageDailyAmount,
    );
  }

  // Get expenses filtered by category and date range
  List<Expense> getFilteredExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return expenses.where((expense) {
      bool categoryMatch =
          category == null || category.isEmpty || expense.category == category;
      bool dateMatch = true;

      if (startDate != null) {
        dateMatch = dateMatch && !expense.date.isBefore(startDate);
      }

      if (endDate != null) {
        dateMatch = dateMatch && !expense.date.isAfter(endDate);
      }

      return categoryMatch && dateMatch;
    }).toList();
  }

  // Get total amount by category
  Map<String, double> getTotalByCategory() {
    final result = <String, double>{};

    for (final category in categories) {
      final total = expenses
          .where((e) => e.category == category)
          .fold(0.0, (sum, e) => sum + e.amount);

      result[category] = total;
    }

    return result;
  }

  // Get daily totals for line chart
  Map<DateTime, double> getDailyTotals() {
    final result = <DateTime, double>{};

    for (final expense in expenses) {
      final date =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      result[date] = (result[date] ?? 0) + expense.amount;
    }

    return result;
  }

  // Get daily totals by category for bar chart
  Map<DateTime, Map<String, double>> getDailyTotalsByCategory() {
    final result = <DateTime, Map<String, double>>{};

    for (final expense in expenses) {
      final date =
          DateTime(expense.date.year, expense.date.month, expense.date.day);

      if (!result.containsKey(date)) {
        result[date] = {};
      }

      final categoryMap = result[date]!;
      categoryMap[expense.category] =
          (categoryMap[expense.category] ?? 0) + expense.amount;
    }

    return result;
  }
}
