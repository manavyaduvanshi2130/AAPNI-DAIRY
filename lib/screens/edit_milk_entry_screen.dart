import 'package:flutter/material.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/milk_entry.dart';

class EditMilkEntryScreen extends StatefulWidget {
  final MilkEntry entry;

  const EditMilkEntryScreen({Key? key, required this.entry}) : super(key: key);

  @override
  State<EditMilkEntryScreen> createState() => _EditMilkEntryScreenState();
}

class _EditMilkEntryScreenState extends State<EditMilkEntryScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController quantityController;
  late TextEditingController fatController;

  @override
  void initState() {
    super.initState();
    quantityController =
        TextEditingController(text: widget.entry.quantity.toString());
    fatController = TextEditingController(text: widget.entry.fat.toString());
  }

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      double fat = double.parse(fatController.text);
      double qty = double.parse(quantityController.text);
      double rate = 8 * fat + 2;
      double amount = rate * qty;

      MilkEntry updated = MilkEntry(
        id: widget.entry.id,
        customerId: widget.entry.customerId,
        date: widget.entry.date,
        shift: widget.entry.shift,
        quantity: qty,
        fat: fat,
        rate: rate,
        amount: amount,
      );

      await dbHelper.updateMilkEntry(updated);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Milk Entry")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity (L)"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Enter quantity" : null,
              ),
              TextFormField(
                controller: fatController,
                decoration: const InputDecoration(labelText: "Fat"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter fat" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEntry,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
