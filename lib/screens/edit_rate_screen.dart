import 'package:flutter/material.dart';
import 'package:aapni_dairy/constants.dart';
import 'package:aapni_dairy/db/db_helper.dart';

class EditRateScreen extends StatefulWidget {
  const EditRateScreen({Key? key}) : super(key: key);

  @override
  _EditRateScreenState createState() => _EditRateScreenState();
}

class _EditRateScreenState extends State<EditRateScreen> {
  final TextEditingController _aController = TextEditingController(text: Constants.rateConstantA.toString());
  final TextEditingController _bController = TextEditingController(text: Constants.rateConstantB.toString());

  void _saveConstants() async {
    double a = double.parse(_aController.text);
    double b = double.parse(_bController.text);
    Constants.rateConstantA = a;
    Constants.rateConstantB = b;

    // Save to database
    final dbHelper = DatabaseHelper();
    await dbHelper.saveSetting('rateConstantA', a.toString());
    await dbHelper.saveSetting('rateConstantB', b.toString());

    // Notify listeners or update state to reflect changes in rate constants
    // For example, you might use a state management solution or event bus
    // Here, we just pop back to previous screen with a result indicating update
    Navigator.of(context).pop(true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Constants updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Rate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _aController,
              decoration: const InputDecoration(
                labelText: 'Constant A (8)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bController,
              decoration: const InputDecoration(
                labelText: 'Constant B (2)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveConstants,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
