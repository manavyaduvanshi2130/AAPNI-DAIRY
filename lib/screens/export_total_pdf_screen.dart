import 'dart:typed_data';
import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
// Removed share_plus import as it is not available
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/constants.dart';

class ExportTotalPdfScreen extends StatefulWidget {
  @override
  _ExportTotalPdfScreenState createState() => _ExportTotalPdfScreenState();
}

class _ExportTotalPdfScreenState extends State<ExportTotalPdfScreen> {
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();

  // Pick Start/End Date
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

  // Save the generated PDF to a file and share using Printing.sharePdf
  Future<void> _sharePdf() async {
    try {
      final pdfBytes = await _buildPdfBytes();

      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(
        tempDir.path,
        'milk_summary_${DateFormat('ddMMyyyy').format(_start)}_${DateFormat('ddMMyyyy').format(_end)}.pdf',
      );
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Use Printing.sharePdf to share the PDF file
      await Printing.sharePdf(bytes: pdfBytes, filename: 'milk_summary.pdf');
    } catch (e) {
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share PDF')));
    }
  }

  // Build PDF bytes
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

      final Map<int, Map<String, dynamic>> summaryMap = {};
      for (var entry in entries) {
        final custId = entry.customerId;
        final custName = await db.getCustomerNameById(custId) ?? "Unknown";

        if (!summaryMap.containsKey(custId)) {
          summaryMap[custId] = {'name': custName, 'qty': 0.0, 'amount': 0.0};
        }

        summaryMap[custId]!['qty'] += entry.quantity;
        summaryMap[custId]!['amount'] += entry.amount;
      }

      double totalQty = 0;
      double totalAmount = 0;

      final dataRows = summaryMap.entries.map((e) {
        final id = e.key;
        final data = e.value;
        totalQty += data['qty'];
        totalAmount += data['amount'];
        return [
          id.toString(),
          data['name'],
          data['qty'].toStringAsFixed(2),
          data['amount'].toStringAsFixed(2),
        ];
      }).toList();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Center(
              child: pw.Text(
                '${Constants.dairyName} \n${Constants.ownerName}\nMOB:${Constants.mobileNumber}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Total Milk Collection (${DateFormat('dd-MM-yyyy').format(_start)} to ${DateFormat('dd-MM-yyyy').format(_end)})',
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Customer ID', 'Name', 'Total Qty', 'Amount (₹)'],
              data: dataRows,
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total:  ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${totalQty.toStringAsFixed(2)} L   ₹${totalAmount.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      );

      return pdf.save();
    } catch (e, stack) {
      print('Error generating total PDF: $e\n$stack');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 12.0;
    final verticalPadding = screenWidth < 600 ? 12.0 : 8.0;
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Milk Collection PDF'),
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
            // Date Selection Section
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
                      // Start Date Box
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16, // Height बढ़ाई गई
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
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
                      // End Date Box
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16, // Height बढ़ाई गई
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
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
                ],
              ),
            ),

            // Share PDF Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.share, color: Colors.white),
                label: Text(
                  'Share PDF',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: _sharePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: Colors.green.shade200,
                ),
              ),
            ),

            SizedBox(height: 16),

            // PDF Preview Section
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
                    allowSharing: false,
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
