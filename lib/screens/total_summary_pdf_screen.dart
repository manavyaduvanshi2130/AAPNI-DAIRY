import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/customer.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'package:aapni_dairy/services/pdf_service.dart';

class TotalSummaryPdfScreen extends StatefulWidget {
  const TotalSummaryPdfScreen({Key? key}) : super(key: key);

  @override
  _TotalSummaryPdfScreenState createState() => _TotalSummaryPdfScreenState();
}

class _TotalSummaryPdfScreenState extends State<TotalSummaryPdfScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Future<void> _generatePdf() async {
    String start = DateFormat('yyyy-MM-dd').format(_startDate);
    String end = DateFormat('yyyy-MM-dd').format(_endDate);
    List<Customer> customers = await DatabaseHelper().getAllCustomers();
    List<Map<String, dynamic>> summaries = [];
    for (var customer in customers) {
      List<MilkEntry> entries = await DatabaseHelper().getMilkEntriesByCustomerAndRange(customer.id!, start, end);
      double totalMilk = entries.fold(0, (sum, entry) => sum + entry.quantity);
      double totalAmount = entries.fold(0, (sum, entry) => sum + entry.amount);
      if (totalMilk > 0) {
        summaries.add({
          'name': customer.name,
          'totalMilk': totalMilk,
          'totalAmount': totalAmount,
        });
      }
    }
    await PdfService().generateTotalSummaryPdf(summaries, start, end);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generated')),
    );
  }

  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Summary PDF'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text('Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickStartDate,
            ),
            ListTile(
              title: Text('End Date: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickEndDate,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generatePdf,
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
