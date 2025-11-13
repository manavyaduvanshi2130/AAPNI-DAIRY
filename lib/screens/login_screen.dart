import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../db/db_helper.dart';
import '../models/customer.dart';
import '../models/milk_entry.dart';
import '../constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dairyNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isAgreed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dairyNameController.text = prefs.getString('dairyName') ?? '';
      _ownerNameController.text = prefs.getString('ownerName') ?? '';
      _mobileController.text = prefs.getString('mobileNumber') ?? '';
    });
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    // For signup, check if agreed to terms
    if (!_isLogin && !_isAgreed) {
      setState(() {
        _errorMessage = 'Please agree to the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Login
        await _authService.signIn(
          _emailController.text,
          _passwordController.text,
        );

        // Migrate local data to Firestore if first login
        await _migrateLocalDataIfNeeded();

        // Save dairy details to SharedPreferences
        await _saveDairyDetails();

        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                dairyName: _dairyNameController.text,
                ownerName: _ownerNameController.text,
                mobileNumber: _mobileController.text,
              ),
            ),
          );
        }
      } else {
        // Sign up
        await _authService.signUp(
          _emailController.text,
          _passwordController.text,
        );

        // Save dairy details to SharedPreferences
        await _saveDairyDetails();

        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                dairyName: _dairyNameController.text,
                ownerName: _ownerNameController.text,
                mobileNumber: _mobileController.text,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _migrateLocalDataIfNeeded() async {
    try {
      // Check if migration already done
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool('dataMigrated') ?? false;
      if (migrated) return;

      // Get local data
      final customers = await DatabaseHelper().getAllCustomers();
      final milkEntries = await DatabaseHelper().getAllMilkEntries();

      // Get settings
      final settings = <String, String>{};
      final dairyName = await DatabaseHelper().getSetting('dairyName');
      final ownerName = await DatabaseHelper().getSetting('ownerName');
      final mobileNumber = await DatabaseHelper().getSetting('mobileNumber');

      if (dairyName != null) settings['dairyName'] = dairyName;
      if (ownerName != null) settings['ownerName'] = ownerName;
      if (mobileNumber != null) settings['mobileNumber'] = mobileNumber;

      // Migrate to Firestore
      if (customers.isNotEmpty ||
          milkEntries.isNotEmpty ||
          settings.isNotEmpty) {
        await _firestoreService.migrateLocalDataToFirestore(
          customers: customers,
          milkEntries: milkEntries,
          settings: settings,
        );
      }

      // Mark as migrated
      await prefs.setBool('dataMigrated', true);
    } catch (e) {
      print('Error migrating data: $e');
      // Continue anyway - user can still use the app
    }
  }

  Future<void> _saveDairyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dairyName', _dairyNameController.text);
    await prefs.setString('ownerName', _ownerNameController.text);
    await prefs.setString('mobileNumber', _mobileController.text);
    await prefs.setBool('isAgreed', true);

    // Update constants
    Constants.dairyName = _dairyNameController.text;
    Constants.ownerName = _ownerNameController.text;
    Constants.mobileNumber = _mobileController.text;
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text);
      setState(() {
        _errorMessage = 'Password reset email sent. Check your inbox.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    _isLogin ? 'Welcome to 2130 GROUP' : 'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Sign in to access your dairy data'
                        : 'Sign up to start managing your dairy',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dairy details (only for signup)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _dairyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Dairy Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dairy name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter owner name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (value.length != 10) {
                          return 'Please enter valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Agreement Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          onChanged: (value) {
                            setState(() {
                              _isAgreed = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Your data will remain with you only. This is a serverless app that works completely offline. If your app gets uninstalled, complete data will be lost. The company will not be responsible for this.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Auth button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Toggle between login/signup
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign Up"
                          : 'Already have an account? Sign In',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),

                  // Forgot password (only for login)
                  if (_isLogin)
                    TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),

                  const SizedBox(height: 16),
                  Text(
                    'Your data will be securely stored in the cloud and restored on any device after login.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _dairyNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}
