import 'package:flutter/material.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({Key? key, required this.selectedDate, required this.onDateSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != selectedDate) {
          onDateSelected(picked);
        }
      },
    );
  }
}
