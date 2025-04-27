import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ChartContainer extends StatefulWidget {
  final Widget child;
  final String chartType;

  const ChartContainer({
    Key? key,
    required this.child,
    required this.chartType,
  }) : super(key: key);

  @override
  State<ChartContainer> createState() => _ChartContainerState();
}

class _ChartContainerState extends State<ChartContainer> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Download button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download Chart',
                      onPressed: _saveChart,
                    ),
            ],
          ),
        ),

        // Chart content
        Expanded(
          child: Screenshot(
            controller: _screenshotController,
            child: Container(
              color: Colors.white,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveChart() async {
    try {
      setState(() {
        _isSaving = true;
      });

      // Capture the screenshot
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        _showErrorSnackBar('Failed to capture chart image');
        return;
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'expense_${widget.chartType}_chart_$timestamp.png';
      final filePath = '${directory.path}/$fileName';

      // Save the image to a file
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Expense ${widget.chartType} chart',
      );

      _showSuccessSnackBar('Chart saved and ready to share');
    } catch (e) {
      _showErrorSnackBar('Error saving chart: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
