import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
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
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    child: Text(dairyName, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                    child: Text(ownerName),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                    child: Text('Mob: $mobileNumber'),
                  ),
                ],
              ),
            ),

            // Animated Text
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              height: 40,
              color: Colors.yellow.shade100,
              child: Marquee(
                text:
                    '<Welcome to 2130 GROUP><Your data will remain with you only. This is a serverless app that works completely offline. If your app gets uninstalled, complete data will be lost. The company will not be responsible for this>',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 20.0,
                velocity: 50.0,
                pauseAfterRound: const Duration(seconds: 1),
                startPadding: 10.0,
                accelerationDuration: const Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
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
                    _buildAnimatedMenuCard(
                      context,
                      'Customer Registration',
                      Icons.person_add,
                      Colors.green,
                      '/customer_registration',
                      0,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Milk Entry',
                      Icons.local_drink,
                      Colors.orange,
                      '/milk_entry',
                      1,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Edit/Delete Entries',
                      Icons.edit,
                      Colors.purple,
                      '/edit_delete_entries',
                      2,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Edit Rate',
                      Icons.attach_money,
                      Colors.teal,
                      '/edit_rate',
                      3,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Daily Summary',
                      Icons.calendar_today,
                      Colors.indigo,
                      '/daily_summary',
                      4,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Customer Summary PDF',
                      Icons.picture_as_pdf,
                      Colors.red,
                      '/customer_summary_pdf',
                      5,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Export Total PDF',
                      Icons.file_download,
                      Colors.brown,
                      '/export_total_pdf',
                      6,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Total Summary PDF',
                      Icons.summarize,
                      Colors.pink,
                      '/total_summary_pdf',
                      7,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Export Customer PDF',
                      Icons.group,
                      Colors.cyan,
                      '/export_customer_pdf',
                      8,
                    ),
                    _buildAnimatedMenuCard(
                      context,
                      'Settings',
                      Icons.settings,
                      Colors.grey,
                      '/settings',
                      9,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            if (Constants.madeBy.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                  child: Text(Constants.madeBy, textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Icon(icon, size: 40, color: color),
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

  Widget _buildAnimatedMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: _buildMenuCard(context, title, icon, color, route),
          ),
        );
      },
    );
  }
}
