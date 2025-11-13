import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'package:aapni_dairy/constants.dart';

class MilkEntryScreen extends StatefulWidget {
  const MilkEntryScreen({Key? key}) : super(key: key);

  @override
  _MilkEntryScreenState createState() => _MilkEntryScreenState();
}

class _MilkEntryScreenState extends State<MilkEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _snfController = TextEditingController();

  final FocusNode _customerIdFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _fatFocus = FocusNode();
  final FocusNode _snfFocus = FocusNode();

  String? _customerName;
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';
  bool _isAutoShift = true; // Flag to track if shift is automatically set

  @override
  void initState() {
    super.initState();
    _initializeShift();
  }

  // Method to determine shift based on current time
  String _getCurrentShift() {
    DateTime now = DateTime.now();
    // If current time is 12:00 PM or later, set to Evening, otherwise Morning
    return now.hour >= 12 ? 'Evening' : 'Morning';
  }

  // Initialize shift automatically when screen loads
  void _initializeShift() {
    setState(() {
      _selectedShift = _getCurrentShift();
      _isAutoShift = true;
    });
  }

  // Method to update shift if user manually changes it
  void _updateShiftManually(String newShift) {
    setState(() {
      _selectedShift = newShift;
      _isAutoShift = false; // User has manually selected shift
    });
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

  Future<void> _saveMilkEntry() async {
    if (_formKey.currentState!.validate()) {
      int customerId = int.parse(_customerIdController.text);
      double quantity = double.parse(_quantityController.text);
      double fat = double.parse(_fatController.text);
      double snf = _snfController.text.isEmpty
          ? 8.0
          : double.parse(_snfController.text);

      double rate = (Constants.rateConstantA * fat) + Constants.rateConstantB;
      double amount = rate * quantity;

      MilkEntry entry = MilkEntry(
        customerId: customerId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        shift: _selectedShift,
        quantity: quantity,
        fat: fat,
        snf: snf,
        rate: rate,
        amount: amount,
      );

      await DatabaseHelper().insertMilkEntry(entry);

      // Show alert dialog with rate and amount
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Milk Entry Saved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Milk entry saved successfully!'),
                const SizedBox(height: 12),
                Text('📊 Rate: ₹${rate.toStringAsFixed(2)} per liter'),
                Text('💰 Amount: ₹${amount.toStringAsFixed(2)}'),
                Text('🥛 Quantity: ${quantity.toStringAsFixed(2)} L'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      _quantityController.clear();
      _fatController.clear();
      _snfController.clear();
    }
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

  @override
  void dispose() {
    _customerIdController.dispose();
    _quantityController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    _customerIdFocus.dispose();
    _quantityFocus.dispose();
    _fatFocus.dispose();
    _snfFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Milk Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FocusTraversalGroup(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _customerIdController,
                  focusNode: _customerIdFocus,
                  decoration: const InputDecoration(
                    labelText: 'Customer ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _fetchCustomerName(),
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_quantityFocus),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter customer ID';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Invalid customer ID';
                    }
                    if (_customerName == null) {
                      return 'Customer not found';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _customerName == null
                      ? 'Customer Name: '
                      : 'Customer Name: $_customerName',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                  ),
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
                      _updateShiftManually(value);
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
                  focusNode: _quantityFocus,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_fatFocus),
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
                  focusNode: _fatFocus,
                  decoration: const InputDecoration(
                    labelText: 'Fat',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_snfFocus),
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
                  focusNode: _snfFocus,
                  decoration: const InputDecoration(
                    labelText: 'SNF (default 8.0)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onFieldSubmitted: (_) => _saveMilkEntry(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveMilkEntry,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
