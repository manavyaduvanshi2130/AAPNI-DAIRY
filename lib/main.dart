import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
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

  // Set up global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Caught Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Initialize Firebase
  try {
    await FirebaseService().initialize();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // For debugging, rethrow to see the error
    rethrow;
  }

  try {
    if (!kIsWeb) {
      await Constants.loadRates();
    }
    await Constants.loadDairyDetails();
    print('Constants loaded successfully');
  } catch (e) {
    print('Error during initialization: $e');
    // For debugging, rethrow to see the error
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String _dairyName = Constants.dairyName;
  String _ownerName = Constants.ownerName;
  String _mobileNumber = Constants.mobileNumber;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('Starting app initialization...');

      // Check Firebase auth state
      final authService = AuthService();
      final user = authService.currentUser;

      print('Current user: ${user?.email ?? 'null'}');

      if (user != null) {
        // User is logged in, load dairy details and go to home
        print('User is logged in, loading dairy details...');
        await _loadDairyDetails();
        setState(() {
          _isLoggedIn = true;
          _isInitialized = true;
        });
        print('App initialized: showing home screen');
      } else {
        // No user logged in, show auth screen
        print('No user logged in, showing auth screen');
        setState(() {
          _isLoggedIn = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error during app initialization: $e');
      // On error, show auth screen
      setState(() {
        _isLoggedIn = false;
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadDairyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _dairyName = prefs.getString('dairyName') ?? Constants.dairyName;
        _ownerName = prefs.getString('ownerName') ?? Constants.ownerName;
        _mobileNumber =
            prefs.getString('mobileNumber') ?? Constants.mobileNumber;
      });
    } catch (e) {
      print('Error loading dairy details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_isInitialized) {
      return MaterialApp(
        title: 'AAPNI DAIRY',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Initializing AAPNI DAIRY...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'AAPNI DAIRY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: _isLoggedIn
          ? HomeScreen(
              dairyName: _dairyName,
              ownerName: _ownerName,
              mobileNumber: _mobileNumber,
            )
          : const LoginScreen(),
      routes: {
        '/customer_registration': (context) =>
            const CustomerRegistrationScreen(),
        '/milk_entry': (context) => const MilkEntryScreen(),
        '/edit_delete_entries': (context) => const EditDeleteEntriesScreen(),
        '/edit_rate': (context) => const EditRateScreen(),
        '/daily_summary': (context) => const DailySummaryScreen(),
        '/customer_summary_pdf': (context) => const CustomerSummaryPdfScreen(),
        '/export_total_pdf': (context) => ExportTotalPdfScreen(),
        '/export_customer_pdf': (context) => ExportCustomerPdfScreen(),
        '/total_summary_pdf': (context) => const TotalSummaryPdfScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
