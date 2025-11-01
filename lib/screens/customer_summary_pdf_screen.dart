import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'package:aapni_dairy/services/pdf_service.dart';
import 'package:printing/printing.dart';

class CustomerSummaryPdfScreen extends StatefulWidget {
  const CustomerSummaryPdfScreen({Key? key}) : super(key: key);

  @override
  _CustomerSummaryPdfScreenState createState() => _CustomerSummaryPdfScreenState();
}

class _CustomerSummaryPdfScreenState extends State<CustomerSummaryPdfScreen> {
  final TextEditingController _customerIdController = TextEditingController();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _customerName;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _customerIdController.addListener(_fetchCustomerName);
  }

  Future<void> _fetchCustomerName() async {
    if (_customerIdController.text.isEmpty) {
      setState(() {
        _customerName = null;
      });
      return;
    }
    int? id = int.tryParse(_customerIdController.text);
    if (id == null) {
      setState(() {
        _customerName = null;
      });
      return;
    }
    String? name = await DatabaseHelper().getCustomerNameById(id);
    setState(() {
      _customerName = name;
    });
  }

  Future<void> _generateAndSharePdf() async {
    if (_customerIdController.text.isEmpty || _customerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid customer ID')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      int customerId = int.parse(_customerIdController.text);
      String start = DateFormat('yyyy-MM-dd').format(_startDate);
      String end = DateFormat('yyyy-MM-dd').format(_endDate);
      List<MilkEntry> entries = await DatabaseHelper().getMilkEntriesByCustomerAndRange(customerId, start, end);

      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries found for the selected date range')),
        );
        return;
      }

      Uint8List pdfBytes = await PdfService().generateCustomerSummaryPdf(entries, _customerName!, start, end);

      // Share the PDF
      await Printing.sharePdf(bytes: pdfBytes, filename: 'customer_summary_${_customerName}_${DateFormat('ddMMyyyy').format(_startDate)}_${DateFormat('ddMMyyyy').format(_endDate)}.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated and shared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
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
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd-MM-yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Summary PDF'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Customer Selection Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customerIdController,
                        decoration: InputDecoration(
                          labelText: 'Customer ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.person, color: Colors.blue.shade700),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _customerName == null ? 'Customer Name: Not found' : 'Customer Name: $_customerName',
                        style: TextStyle(
                          fontSize: 16,
                          color: _customerName == null ? Colors.red : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date Selection Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start: ${df.format(_startDate)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                              onPressed: _pickStartDate,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'End: ${df.format(_endDate)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                              onPressed: _pickEndDate,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Generate PDF Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateAndSharePdf,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.share),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate & Share PDF',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.green.shade200,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will generate a PDF with customer details, milk entries, and totals for the selected date range.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
