import 'package:flutter/material.dart';
import '../constants.dart';

class HomeScreen extends StatelessWidget {
  final String dairyName;
  final String ownerName;
  final String mobileNumber;

  const HomeScreen({
    super.key,
    required this.dairyName,
    required this.ownerName,
    required this.mobileNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    dairyName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ownerName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    'Mob: $mobileNumber',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      context,
                      'Customer Registration',
                      Icons.person_add,
                      Colors.green,
                      '/customer_registration',
                    ),
                    _buildMenuCard(
                      context,
                      'Milk Entry',
                      Icons.local_drink,
                      Colors.orange,
                      '/milk_entry',
                    ),
                    _buildMenuCard(
                      context,
                      'Edit/Delete Entries',
                      Icons.edit,
                      Colors.purple,
                      '/edit_delete_entries',
                    ),
                    _buildMenuCard(
                      context,
                      'Edit Rate',
                      Icons.attach_money,
                      Colors.teal,
                      '/edit_rate',
                    ),
                    _buildMenuCard(
                      context,
                      'Daily Summary',
                      Icons.calendar_today,
                      Colors.indigo,
                      '/daily_summary',
                    ),
                    _buildMenuCard(
                      context,
                      'Customer Summary PDF',
                      Icons.picture_as_pdf,
                      Colors.red,
                      '/customer_summary_pdf',
                    ),
                    _buildMenuCard(
                      context,
                      'Export Total PDF',
                      Icons.file_download,
                      Colors.brown,
                      '/export_total_pdf',
                    ),
                    _buildMenuCard(
                      context,
                      'Total Summary PDF',
                      Icons.summarize,
                      Colors.pink,
                      '/total_summary_pdf',
                    ),
                    _buildMenuCard(
                      context,
                      'Export Customer PDF',
                      Icons.group,
                      Colors.cyan,
                      '/export_customer_pdf',
                    ),
                    _buildMenuCard(
                      context,
                      'Settings',
                      Icons.settings,
                      Colors.grey,
                      '/settings',
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            if (Constants.madeBy.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Text(
                  Constants.madeBy,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
