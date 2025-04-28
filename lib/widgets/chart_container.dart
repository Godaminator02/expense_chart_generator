import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
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
  final GlobalKey _chartKey = GlobalKey();
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
          child: RepaintBoundary(
            key: _chartKey,
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

      // Add a small delay to ensure the widget is properly rendered
      await Future.delayed(const Duration(milliseconds: 500));

      // Capture the widget as an image
      final RenderRepaintBoundary? boundary = _chartKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _showErrorSnackBar('Failed to find chart widget');
        return;
      }

      // Check if the boundary is ready for rendering
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showErrorSnackBar('Failed to capture chart image');
        return;
      }

      final Uint8List imageBytes = byteData.buffer.asUint8List();

      // Get temporary directory for sharing
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      // Capitalize the chart type for better file naming
      final capitalizedChartType =
          widget.chartType.substring(0, 1).toUpperCase() +
              widget.chartType.substring(1);
      final fileName = 'expense_${capitalizedChartType}_chart_$timestamp.png';
      final filePath = '${directory.path}/$fileName';

      // Save the image to a file for sharing
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Also save to gallery
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: fileName,
        quality: 100,
        isReturnImagePathOfIOS: true,
      );

      // Check if the image was saved successfully
      if (result == null || (result is Map && result['isSuccess'] == false)) {
        _showErrorSnackBar('Failed to save chart to gallery');
        return;
      }

      // Share the file
      try {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Expense $capitalizedChartType Chart',
        );
      } catch (shareError) {
        // If sharing fails, still show success for gallery save
        _showSuccessSnackBar('Chart saved to gallery successfully');
        return;
      }

      _showSuccessSnackBar('Chart saved to gallery and ready to share');
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
