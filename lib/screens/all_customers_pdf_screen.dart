import 'package:flutter/material.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/customer.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'package:aapni_dairy/services/pdf_service.dart';

class AllCustomersPdfScreen extends StatefulWidget {
  const AllCustomersPdfScreen({Key? key}) : super(key: key);

  @override
  _AllCustomersPdfScreenState createState() => _AllCustomersPdfScreenState();
}

class _AllCustomersPdfScreenState extends State<AllCustomersPdfScreen> {
  Future<void> _generatePdf() async {
    List<Customer> customers = await DatabaseHelper().getAllCustomers();
    List<Map<String, dynamic>> summaries = [];
    for (var customer in customers) {
      List<MilkEntry> entries = await DatabaseHelper().getMilkEntriesByCustomer(customer.id!);
      summaries.add({
        'name': customer.name,
        'entries': entries,
      });
    }
    await PdfService().generateAllCustomersPdf(summaries);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers PDF'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _generatePdf,
          child: const Text('Generate All Customers PDF'),
        ),
      ),
    );
  }
}
