import 'package:flutter/material.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:aapni_dairy/models/customer.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({Key? key}) : super(key: key);

  @override
  _CustomerRegistrationScreenState createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  List<Customer> _customers = [];
  bool _showCustomerList = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await DatabaseHelper().getAllCustomers();
    setState(() {
      _customers = customers;
    });
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();

      // Insert customer with auto-increment ID handled by DB
      Customer newCustomer = Customer(name: name);
      await DatabaseHelper().insertCustomer(newCustomer);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer saved successfully')),
      );

      _nameController.clear();
      _loadCustomers(); // Refresh the customer list
      setState(() {
        _showCustomerList = true; // Show customer list after registration
      });
    }
  }

  Future<void> _editCustomer(Customer customer) async {
    final TextEditingController editController = TextEditingController(
      text: customer.name,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Customer'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(labelText: 'Customer Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String newName = editController.text.trim();
                if (newName.isNotEmpty) {
                  Customer updatedCustomer = Customer(
                    id: customer.id!,
                    name: newName,
                  );
                  await DatabaseHelper().updateCustomerByObject(
                    updatedCustomer,
                  );
                  Navigator.of(context).pop();
                  _loadCustomers(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer updated successfully'),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text(
            'Are you sure you want to delete ${customer.name}? This will also delete all their milk entries.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper().deleteCustomerAndResetIds(customer.id!);
                Navigator.of(context).pop();
                _loadCustomers(); // Refresh the list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Customer deleted successfully'),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Registration'),
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
              // Registration Form
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register New Customer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Customer Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.blue.shade700,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter customer name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _saveCustomer,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Customer List Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Customers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showCustomerList = !_showCustomerList;
                      });
                      if (_showCustomerList) {
                        _loadCustomers();
                      }
                    },
                    icon: Icon(
                      _showCustomerList
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    label: Text(_showCustomerList ? 'Hide List' : 'Show List'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Customer List
              if (_showCustomerList)
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _customers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No customers registered yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _customers.length,
                            itemBuilder: (context, index) {
                              final customer = _customers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    customer.id.toString(),
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text('ID: ${customer.id}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue.shade600,
                                      ),
                                      onPressed: () => _editCustomer(customer),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade600,
                                      ),
                                      onPressed: () =>
                                          _deleteCustomer(customer),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
