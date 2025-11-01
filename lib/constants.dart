import 'package:pdf/pdf.dart';
import 'package:aapni_dairy/db/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static String dairyName = 'HRB DAIRY KHEDA RAMPURA';
  static String ownerName = 'MAHESH KUMAR YADAV';
  static String mobileNumber = '9876543210';
  static const String madeBy = '';

  static double rateConstantA = 8.0;
  static double rateConstantB = 2.0;

  // Default PDF page formats
  static const PdfPageFormat defaultPageFormat = PdfPageFormat.a4;
  static const double defaultTitleFontSize = 20.0;
  static const double defaultTableFontSize = 10.0;
  static const double minFontSize = 6.0;
  static const double maxFontSize = 16.0;

  // Available page formats
  static const Map<String, PdfPageFormat> pageFormats = {
    'A4': PdfPageFormat.a4,
    'A5': PdfPageFormat.a5,
    'Letter': PdfPageFormat.letter,
    'Legal': PdfPageFormat.legal,
  };

  // Load rates from database
  static Future<void> loadRates() async {
    final dbHelper = DatabaseHelper();
    final aValue = await dbHelper.getSetting('rateConstantA');
    final bValue = await dbHelper.getSetting('rateConstantB');

    if (aValue != null) {
      rateConstantA = double.tryParse(aValue) ?? 8.0;
    }
    if (bValue != null) {
      rateConstantB = double.tryParse(bValue) ?? 2.0;
    }
  }

  // Load dairy details from shared preferences
  static Future<void> loadDairyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    dairyName = prefs.getString('dairyName') ?? dairyName;
    ownerName = prefs.getString('ownerName') ?? ownerName;
    mobileNumber = prefs.getString('mobileNumber') ?? mobileNumber;
  }
}
