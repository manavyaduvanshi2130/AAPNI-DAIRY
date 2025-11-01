import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:aapni_dairy/constants.dart';
import 'package:aapni_dairy/models/milk_entry.dart';

class PdfService {
  Future<Uint8List> generateCustomerSummaryPdf(List<MilkEntry> entries, String customerName, String startDate, String endDate) async {
    final pdf = pw.Document();
    double totalQuantity = entries.fold(0, (sum, entry) => sum + entry.quantity);
    double totalAmount = entries.fold(0, (sum, entry) => sum + entry.amount);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(Constants.dairyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(Constants.ownerName),
              pw.Text('Mob: ${Constants.mobileNumber}'),
              pw.SizedBox(height: 20),
              pw.Text('Customer Summary for $customerName'),
              pw.Text('From $startDate to $endDate'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Shift', 'Quantity', 'Fat', 'Rate', 'Amount'],
                data: entries.map((entry) => [
                  entry.date,
                  entry.shift,
                  entry.quantity.toStringAsFixed(2),
                  entry.fat.toStringAsFixed(2),
                  entry.rate.toStringAsFixed(2),
                  entry.amount.toStringAsFixed(2),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Quantity: ${totalQuantity.toStringAsFixed(2)}'),
              pw.Text('Total Amount: ${totalAmount.toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> generateAllCustomersPdf(List<Map<String, dynamic>> customerSummaries) async {
    final pdf = pw.Document();

    for (var summary in customerSummaries) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(Constants.dairyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text(Constants.ownerName),
                pw.Text('Mob: ${Constants.mobileNumber}'),
                pw.SizedBox(height: 20),
                pw.Text('Customer: ${summary['name']}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Shift', 'Quantity', 'Fat', 'SNF', 'Amount'],
                  data: (summary['entries'] as List<MilkEntry>).map((entry) => [
                    entry.date,
                    entry.shift,
                    entry.quantity.toStringAsFixed(2),
                    entry.fat.toStringAsFixed(2),
                    entry.snf.toStringAsFixed(2),
                    entry.amount.toStringAsFixed(2),
                  ]).toList(),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'all_customers_summary.pdf');
  }

  Future<void> generateTotalSummaryPdf(List<Map<String, dynamic>> summaries, String startDate, String endDate) async {
    final pdf = pw.Document();
    double grandTotalMilk = summaries.fold(0, (sum, s) => sum + s['totalMilk']);
    double grandTotalAmount = summaries.fold(0, (sum, s) => sum + s['totalAmount']);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(Constants.dairyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(Constants.ownerName),
              pw.Text('Mob: ${Constants.mobileNumber}'),
              pw.SizedBox(height: 20),
              pw.Text('Total Summary from $startDate to $endDate'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Customer', 'Total Milk', 'Total Amount'],
                data: summaries.map((s) => [
                  s['name'],
                  s['totalMilk'].toStringAsFixed(2),
                  s['totalAmount'].toStringAsFixed(2),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Grand Total Milk: ${grandTotalMilk.toStringAsFixed(2)}'),
              pw.Text('Grand Total Amount: ${grandTotalAmount.toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'total_summary.pdf');
  }

  // Method 1: Customer ID, Date, Shift, Quantity, Fat, Rate, Amount with totals
  Future<Uint8List> generateCustomerSummaryPdfMethod1(List<MilkEntry> entries, String customerName, String date) async {
    final pdf = pw.Document();
    double totalQuantity = entries.fold(0, (sum, entry) => sum + entry.quantity);
    double totalAmount = entries.fold(0, (sum, entry) => sum + entry.amount);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(Constants.dairyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(Constants.ownerName),
              pw.Text('Mob: ${Constants.mobileNumber}'),
              pw.SizedBox(height: 20),
              pw.Text('Customer: $customerName'),
              pw.Text('Date: $date'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Customer ID', 'Date', 'Shift', 'Quantity', 'Fat', 'Rate', 'Amount'],
                data: entries.map((entry) => [
                  entry.customerId.toString(),
                  entry.date,
                  entry.shift,
                  entry.quantity.toStringAsFixed(2),
                  entry.fat.toStringAsFixed(2),
                  entry.rate.toStringAsFixed(2),
                  entry.amount.toStringAsFixed(2),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Quantity: ${totalQuantity.toStringAsFixed(2)}'),
              pw.Text('Total Amount: ${totalAmount.toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Method 2: Customer ID, Date, Shift, Fat, SNF, Amount with totals
  Future<Uint8List> generateCustomerSummaryPdfMethod2(List<MilkEntry> entries, String customerName, String date) async {
    final pdf = pw.Document();
    double totalQuantity = entries.fold(0, (sum, entry) => sum + entry.quantity);
    double totalAmount = entries.fold(0, (sum, entry) => sum + entry.amount);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(Constants.dairyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(Constants.ownerName),
              pw.Text('Mob: ${Constants.mobileNumber}'),
              pw.SizedBox(height: 20),
              pw.Text('Customer: $customerName'),
              pw.Text('Date: $date'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Customer ID', 'Date', 'Shift', 'Fat', 'SNF', 'Amount'],
                data: entries.map((entry) => [
                  entry.customerId.toString(),
                  entry.date,
                  entry.shift,
                  entry.fat.toString(),
                  entry.snf.toString(),
                  entry.amount.toString(),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Quantity: $totalQuantity'),
              pw.Text('Total Amount: $totalAmount'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
