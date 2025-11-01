import 'package:flutter/material.dart';

class CommonSummaryCard extends StatelessWidget {
  final String title;
  final double totalMilk;
  final double totalAmount;

  const CommonSummaryCard({
    Key? key,
    required this.title,
    required this.totalMilk,
    required this.totalAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total Milk: $totalMilk L'),
            Text('Total Amount: ₹$totalAmount'),
          ],
        ),
      ),
    );
  }
}
