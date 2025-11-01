import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'package:aapni_dairy/constants.dart';

class ExportCustomerPdfScreen extends StatefulWidget {
  @override
  _ExportCustomerPdfScreenState createState() =>
      _ExportCustomerPdfScreenState();
}

class _ExportCustomerPdfScreenState extends State<ExportCustomerPdfScreen> {
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  String _selectedMethod = 'Method 1';

  String _selectedPageFormat = 'A4';
  double _titleFontSize = Constants.defaultTitleFontSize;
  double _tableFontSize = Constants.defaultTableFontSize;
  bool _autoFitText = true;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          if (_start.isAfter(_end)) _end = _start;
        } else {
          _end = picked;
          if (_end.isBefore(_start)) _start = _end;
        }
      });
    }
  }

  Map<String, double> _calculateFontSizes(int entryCount) {
    if (!_autoFitText) {
      return {
        'title': _titleFontSize,
        'table': _tableFontSize,
      };
    }

    const double baseTitleSize = 20.0;
    const double baseTableSize = 10.0;
    const int baseEntryCount = 10;

    double scaleFactor = baseEntryCount / entryCount.clamp(1, 50);

    return {
      'title': (baseTitleSize * scaleFactor)
          .clamp(Constants.minFontSize, Constants.maxFontSize),
      'table': (baseTableSize * scaleFactor)
          .clamp(Constants.minFontSize, Constants.maxFontSize),
    };
  }

  Future<Uint8List> _buildPdfBytes() async {
    try {
      final db = DatabaseHelper();
      final entries = await db.getMilkEntriesInRange(
        DateFormat('yyyy-MM-dd').format(_start),
        DateFormat('yyyy-MM-dd').format(_end),
      );

      if (entries.isEmpty) {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Center(
              child: pw.Text('No milk entries found for selected date range.'),
            ),
          ),
        );
        return pdf.save();
      }

      final Map<int, List<MilkEntry>> customerEntries = {};
      final Map<int, String> customerNames = {};

      for (var entry in entries) {
        final custId = entry.customerId;
        if (!customerEntries.containsKey(custId)) {
          customerEntries[custId] = [];
          customerNames[custId] =
              await db.getCustomerNameById(custId) ?? "Unknown";
        }
        customerEntries[custId]!.add(entry);
      }

      // Sort customer IDs in ascending order
      List<int> sortedCustomerIds = customerEntries.keys.toList()..sort();

      final pdfDoc = pw.Document();

      for (var custId in sortedCustomerIds) {
        final customerName = customerNames[custId]!;
        final custEntries = customerEntries[custId]!;

        double totalQuantity =
            custEntries.fold(0, (sum, entry) => sum + entry.quantity);
        double totalAmount =
            custEntries.fold(0, (sum, entry) => sum + entry.amount);

        // Split entries into chunks of 30
        List<List<MilkEntry>> chunks = [];
        for (int i = 0; i < custEntries.length; i += 30) {
          chunks.add(custEntries.sublist(
              i, i + 30 > custEntries.length ? custEntries.length : i + 30));
        }

        for (int pageIndex = 0; pageIndex < chunks.length; pageIndex++) {
          final chunk = chunks[pageIndex];
          final fontSizes = _calculateFontSizes(chunk.length);

          pdfDoc.addPage(
            pw.Page(
              pageFormat: Constants.pageFormats[_selectedPageFormat]!,
              build: (pw.Context context) {
                double pageWidth = Constants.pageFormats[_selectedPageFormat]!.width;

                final pw.Widget table = _selectedMethod == 'Method 1'
                    ? pw.Table.fromTextArray(
                        headerStyle: pw.TextStyle(
                          fontSize: fontSizes['table'],
                          fontWeight: pw.FontWeight.bold,
                        ),
                        cellStyle: pw.TextStyle(fontSize: fontSizes['table']),
                        headers: [
                          'Date',
                          'Shift',
                          'Quantity',
                          'Fat',
                          'Rate',
                          'Amount',
                        ],
                        data: chunk
                            .map(
                              (entry) => [
                                entry.date,
                                entry.shift,
                                entry.quantity.toStringAsFixed(2),
                                entry.fat.toStringAsFixed(2),
                                entry.rate.toStringAsFixed(2),
                                entry.amount.toStringAsFixed(2),
                              ],
                            )
                            .toList(),
                      )
                    : pw.Table.fromTextArray(
                        headerStyle: pw.TextStyle(
                          fontSize: fontSizes['table'],
                          fontWeight: pw.FontWeight.bold,
                        ),
                        cellStyle: pw.TextStyle(fontSize: fontSizes['table']),
                        headers: ['Date', 'Shift', 'Quantity', 'Fat', 'SNF', 'Amount'],
                        data: chunk
                            .map(
                              (entry) => [
                                entry.date,
                                entry.shift,
                                entry.quantity.toStringAsFixed(2),
                                entry.fat.toStringAsFixed(2),
                                entry.snf.toStringAsFixed(2),
                                entry.amount.toStringAsFixed(2),
                              ],
                            )
                            .toList(),
                      );

                return pw.Container(
                  width: pageWidth * 2 / 3,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        Constants.dairyName,
                        style: pw.TextStyle(
                          fontSize: fontSizes['title'],
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${Constants.ownerName} Mob:${Constants.mobileNumber}',
                        style: pw.TextStyle(fontSize: fontSizes['table']),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Customer: $customerName (ID: $custId)',
                        style: pw.TextStyle(fontSize: fontSizes['table']),
                      ),
                      pw.Text(
                        'Date Range: ' + DateFormat("dd-MM-yyyy").format(_start) + ' to ' + DateFormat("dd-MM-yyyy").format(_end),
                        style: pw.TextStyle(fontSize: fontSizes['table']),
                      ),
                      pw.SizedBox(height: 10),
                      table,
                      if (pageIndex == chunks.length - 1) ...[
                        pw.SizedBox(height: 20),
                        pw.Text(
                          'Total Quantity: ${totalQuantity.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: fontSizes['table']),
                        ),
                        pw.Text(
                          'Total Amount: ${totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: fontSizes['table']),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        }
      }

      return pdfDoc.save();
    } catch (e, stack) {
      print('Error generating customer PDF: $e\n$stack');
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) =>
              pw.Center(child: pw.Text('Error generating PDF.')),
        ),
      );
      return pdf.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Export Customer PDF'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      // Start Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    df.format(_start),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _pickDate(true),
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: Colors.blue.shade700,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // End Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    df.format(_end),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _pickDate(false),
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: Colors.blue.shade700,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  DropdownButton<String>(
                    value: _selectedMethod,
                    items: const [
                      DropdownMenuItem(
                        value: 'Method 1',
                        child: Text('Method 1'),
                      ),
                      DropdownMenuItem(
                        value: 'Method 2',
                        child: Text('Method 2'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMethod = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Page Format',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedPageFormat,
                    isExpanded: true,
                    items: Constants.pageFormats.keys.map((format) {
                      return DropdownMenuItem(
                        value: format,
                        child: Text(format),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPageFormat = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Auto-fit Text',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Spacer(),
                      Switch(
                        value: _autoFitText,
                        onChanged: (value) {
                          setState(() {
                            _autoFitText = value;
                          });
                        },
                        activeColor: Colors.blue.shade700,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (!_autoFitText) ...[
                    Text(
                      'Title Font Size: ${_titleFontSize.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Slider(
                      value: _titleFontSize,
                      min: Constants.minFontSize,
                      max: Constants.maxFontSize,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          _titleFontSize = value;
                        });
                      },
                      activeColor: Colors.blue.shade700,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Table Font Size: ${_tableFontSize.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Slider(
                      value: _tableFontSize,
                      min: Constants.minFontSize,
                      max: Constants.maxFontSize,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          _tableFontSize = value;
                        });
                      },
                      activeColor: Colors.blue.shade700,
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PdfPreview(
                    build: (format) => _buildPdfBytes(),
                    canChangePageFormat: false,
                    allowPrinting: true,
                    allowSharing: true,
                    loadingWidget: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Generating PDF...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onError: (context, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error generating PDF',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
