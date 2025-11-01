import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/milk_entry.dart';

class EditDeleteEntriesScreen extends StatefulWidget {
  const EditDeleteEntriesScreen({Key? key}) : super(key: key);

  @override
  _EditDeleteEntriesScreenState createState() => _EditDeleteEntriesScreenState();
}

class _EditDeleteEntriesScreenState extends State<EditDeleteEntriesScreen> {
  final TextEditingController _customerIdController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<MilkEntry> _entries = [];

  Future<void> _fetchEntries() async {
    if (_customerIdController.text.isEmpty) {
      setState(() {
        _entries = [];
      });
      return;
    }
    int? customerId = int.tryParse(_customerIdController.text);
    if (customerId == null) {
      setState(() {
        _entries = [];
      });
      return;
    }
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<MilkEntry> entries = await DatabaseHelper().getMilkEntriesByCustomerAndRange(customerId, dateStr, dateStr);
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchEntries();
    }
  }

  Future<void> _deleteEntry(int id) async {
    await DatabaseHelper().deleteMilkEntry(id);
    await _fetchEntries();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry deleted')),
    );
  }

  void _editEntry(MilkEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMilkEntryScreen(entry: entry),
      ),
    );
    if (result == true) {
      await _fetchEntries();
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit/Delete Entries'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _customerIdController,
              decoration: const InputDecoration(
                labelText: 'Customer ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _fetchEntries(),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: Text('No entries found'))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Card(
                          child: ListTile(
                            title: Text('Shift: ${entry.shift}, Quantity: ${entry.quantity}, Fat: ${entry.fat}'),
                            subtitle: Text('Rate: ${entry.rate}, Amount: ${entry.amount}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editEntry(entry),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteEntry(entry.id!),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditMilkEntryScreen extends StatefulWidget {
  final MilkEntry entry;

  const EditMilkEntryScreen({Key? key, required this.entry}) : super(key: key);

  @override
  _EditMilkEntryScreenState createState() => _EditMilkEntryScreenState();
}

class _EditMilkEntryScreenState extends State<EditMilkEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _fatController;
  late TextEditingController _snfController;
  late String _selectedShift;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.entry.quantity.toString());
    _fatController = TextEditingController(text: widget.entry.fat.toString());
    _snfController = TextEditingController(text: widget.entry.snf.toString());
    _selectedShift = widget.entry.shift;
    _selectedDate = DateTime.parse(widget.entry.date);
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      double quantity = double.parse(_quantityController.text);
      double fat = double.parse(_fatController.text);
      double snf = _snfController.text.isEmpty ? 8.0 : double.parse(_snfController.text);

      MilkEntry updatedEntry = MilkEntry(
        id: widget.entry.id,
        customerId: widget.entry.customerId,
        date: _selectedDate.toIso8601String().split('T')[0],
        shift: _selectedShift,
        quantity: quantity,
        fat: fat,
        snf: snf,
      );

      await DatabaseHelper().updateMilkEntry(updatedEntry);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry updated successfully')),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Milk Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedShift,
                items: const [
                  DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                  DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedShift = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Shift',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(
                  labelText: 'Fat',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter fat';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid fat';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _snfController,
                decoration: const InputDecoration(
                  labelText: 'SNF (default 8.0)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveEntry,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
