import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'package:aapni_dairy/widgets/custom_date_picker.dart';
import 'package:aapni_dairy/widgets/common_summary_card.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({Key? key}) : super(key: key);

  @override
  _DailySummaryScreenState createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  double _morningMilk = 0;
  double _morningAmount = 0;
  double _eveningMilk = 0;
  double _eveningAmount = 0;

  Future<void> _fetchSummary() async {
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<MilkEntry> entries = await DatabaseHelper().getMilkEntriesByDate(dateStr);
    double morningMilk = 0;
    double morningAmount = 0;
    double eveningMilk = 0;
    double eveningAmount = 0;
    for (var entry in entries) {
      if (entry.shift == 'Morning') {
        morningMilk += entry.quantity;
        morningAmount += entry.amount;
      } else {
        eveningMilk += entry.quantity;
        eveningAmount += entry.amount;
      }
    }
    setState(() {
      _morningMilk = morningMilk;
      _morningAmount = morningAmount;
      _eveningMilk = eveningMilk;
      _eveningAmount = eveningAmount;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomDatePicker(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _fetchSummary();
              },
            ),
            const SizedBox(height: 16),
            CommonSummaryCard(
              title: 'Morning Shift',
              totalMilk: _morningMilk,
              totalAmount: _morningAmount,
            ),
            const SizedBox(height: 16),
            CommonSummaryCard(
              title: 'Evening Shift',
              totalMilk: _eveningMilk,
              totalAmount: _eveningAmount,
            ),
          ],
        ),
      ),
    );
  }
}
