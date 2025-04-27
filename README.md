# Expense Chart Generator

A Flutter application that allows users to visualize expense data from CSV files using various chart types.

## Features

- **CSV File Import**: Upload CSV files containing expense data with Date, Category, and Amount columns.
- **Multiple Chart Types**: Visualize data using Bar Charts, Pie Charts, and Line Charts.
- **Data Filtering**: Filter data by category and date range.
- **Responsive Design**: Works on both phones and tablets.
- **Offline Functionality**: Works completely offline, no internet connection required.
- **Sample Data**: Includes sample expense data for demonstration purposes.

## Chart Types

### Bar Chart
- Shows daily expenses grouped by category.
- X-axis represents dates, Y-axis represents amounts.
- Categories are color-coded.
- Includes tooltips showing detailed information when hovering over bars.

### Pie Chart
- Shows total spending per category.
- Each slice represents a category with its percentage of total spending.
- Includes a legend showing category names, amounts, and percentages.

### Line Chart
- Shows spending trends over time.
- Includes a 7-day moving average line (when enough data is available).
- Tooltips show detailed information for each data point.

## Data Requirements

The CSV file should contain at least the following columns:
- **Date**: The date of the expense (supports various date formats).
- **Category**: The category of the expense (e.g., Groceries, Utilities, etc.).
- **Amount**: The amount of the expense.

Example CSV format:
```
Date,Category,Amount
2025-01-01,Groceries,120.50
2025-01-02,Utilities,85.75
2025-01-03,Dining,45.20
```

## Getting Started

1. Launch the application.
2. Either:
   - Click **"Select CSV File"** to upload your own CSV file, or
   - Click **"Load Sample Data"** to use the included sample data.
3. Once data is loaded, use the chart type selector to switch between Bar, Pie, and Line charts.
4. Use the category dropdown and date range selectors to filter the data as needed.
5. The summary statistics at the bottom show the total and average spending for the filtered data.

## Installation Process

To set up the project locally, follow these steps:

### 1. Clone the repository
```bash
git clone https://github.com/your-username/expense-chart-generator.git
cd expense-chart-generator
```

### 2. Install Flutter dependencies
```bash
flutter pub get
```

### 3. Run the application
- **For mobile (Android/iOS)**:
  ```bash
  flutter run
  ```

> **Note**: Make sure you have Flutter installed. You can check by running:
> ```bash
> flutter doctor
> ```

## Technical Details

This application is built using:
- **Flutter** for the UI
- **GetX** for state management
- **fl_chart** for chart visualization
- **csv** package for parsing CSV files
- **file_picker** for selecting CSV files
- **intl** for date and number formatting

