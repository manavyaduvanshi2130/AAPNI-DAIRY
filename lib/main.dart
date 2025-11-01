import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/customer_registration_screen.dart';
import 'screens/milk_entry_screen.dart';
import 'screens/edit_delete_entries_screen.dart';
import 'screens/edit_rate_screen.dart';
import 'screens/daily_summary_screen.dart';
import 'screens/customer_summary_pdf_screen.dart';
import 'screens/export_total_pdf_screen.dart';
import 'screens/export_customer_pdf_screen.dart';
import 'screens/total_summary_pdf_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!kIsWeb) {
      await Constants.loadRates();
    }
    await Constants.loadDairyDetails();
  } catch (e) {
    print('Error during initialization: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  String _dairyName = Constants.dairyName;
  String _ownerName = Constants.ownerName;
  String _mobileNumber = Constants.mobileNumber;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isAgreed = prefs.getBool('isAgreed') ?? false;
    await _loadDairyDetails();
    setState(() {
      _isLoggedIn = isAgreed;
    });
  }

  Future<void> _loadDairyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dairyName = prefs.getString('dairyName') ?? Constants.dairyName;
      _ownerName = prefs.getString('ownerName') ?? Constants.ownerName;
      _mobileNumber = prefs.getString('mobileNumber') ?? Constants.mobileNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AAPNI DAIRY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: _isLoggedIn ? HomeScreen(
        dairyName: _dairyName,
        ownerName: _ownerName,
        mobileNumber: _mobileNumber,
      ) : const LoginScreen(),
      routes: {
        '/customer_registration': (context) => const CustomerRegistrationScreen(),
        '/milk_entry': (context) => const MilkEntryScreen(),
        '/edit_delete_entries': (context) => const EditDeleteEntriesScreen(),
        '/edit_rate': (context) => const EditRateScreen(),
        '/daily_summary': (context) => const DailySummaryScreen(),
        '/customer_summary_pdf': (context) => const CustomerSummaryPdfScreen(),
        '/export_total_pdf': (context) => ExportTotalPdfScreen(),
        '/export_customer_pdf': (context) => ExportCustomerPdfScreen(),
        '/total_summary_pdf': (context) => const TotalSummaryPdfScreen(),
        '/settings': (context) => SettingsScreen(
          onSaved: _loadDairyDetails,
        ),
      },
    );
  }
}


