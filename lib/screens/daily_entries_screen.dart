import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'edit_milk_entry_screen.dart'; // ✅ Import the edit screen

class DailyEntriesScreen extends StatefulWidget {
  const DailyEntriesScreen({Key? key}) : super(key: key);

  @override
  _DailyEntriesScreenState createState() => _DailyEntriesScreenState();
}

class _DailyEntriesScreenState extends State<DailyEntriesScreen> {
  Map<String, Map<String, List<MilkEntry>>> _entriesByDateShift = {};

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    List<MilkEntry> entries = await DatabaseHelper().getAllMilkEntries();
    Map<String, Map<String, List<MilkEntry>>> grouped = {};

    for (var entry in entries) {
      grouped.putIfAbsent(entry.date, () => {});
      grouped[entry.date]!.putIfAbsent(entry.shift, () => []);
      grouped[entry.date]![entry.shift]!.add(entry);
    }

    setState(() {
      _entriesByDateShift = grouped;
    });
  }

  Future<void> _deleteEntry(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().deleteMilkEntry(id);
      await _loadEntries();
    }
  }

  Future<void> _editEntry(MilkEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMilkEntryScreen(entry: entry),
      ),
    );

    if (result == true) {
      await _loadEntries(); // Refresh list after successful edit
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Milk Entries')),
      body: _entriesByDateShift.isEmpty
          ? const Center(child: Text('No entries available.'))
          : ListView(
              children: _entriesByDateShift.entries.map((dateEntry) {
                DateTime? parsedDate;
                try {
                  parsedDate = DateTime.parse(dateEntry.key);
                } catch (e) {
                  parsedDate = null;
                }
                String formattedDate = parsedDate != null
                    ? DateFormat('dd-MM-yyyy').format(parsedDate)
                    : dateEntry.key;

                double dayTotalQty = 0;
                double dayTotalAmount = 0;

                dateEntry.value.forEach((shift, list) {
                  for (var e in list) {
                    dayTotalQty += e.quantity;
                    dayTotalAmount += e.amount;
                  }
                });

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(
                      'Date: $formattedDate',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Total Qty: ${dayTotalQty.toStringAsFixed(2)} L  |  ₹${dayTotalAmount.toStringAsFixed(2)}',
                    ),
                    children: dateEntry.value.entries.map((shiftEntry) {
                      double shiftQty = 0;
                      double shiftAmount = 0;

                      for (var e in shiftEntry.value) {
                        shiftQty += e.quantity;
                        shiftAmount += e.amount;
                      }

                      return ExpansionTile(
                        title: Text(
                          '${shiftEntry.key} Shift',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        subtitle: Text(
                          'Qty: ${shiftQty.toStringAsFixed(2)} L  |  ₹${shiftAmount.toStringAsFixed(2)}',
                        ),
                        children: shiftEntry.value.map((e) {
                          return ListTile(
                            title: Text('Customer ID: ${e.customerId}'),
                            subtitle: Text(
                              'Qty: ${e.quantity}, Fat: ${e.fat}, Rate: ₹${e.rate}, Amount: ₹${e.amount.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.green),
                                  onPressed: () => _editEntry(e),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: e.id == null ? null : () => _deleteEntry(e.id!),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
