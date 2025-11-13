import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:aapni_dairy/models/customer.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'package:aapni_dairy/constants.dart';
import 'package:aapni_dairy/services/firestore_service.dart';
import 'package:aapni_dairy/services/firebase_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final FirestoreService _firestoreService = FirestoreService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'milk_management.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON"); // Enable cascade delete
      },
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE milk_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        shift TEXT NOT NULL,
        quantity REAL NOT NULL,
        fat REAL NOT NULL,
        snf REAL DEFAULT 8.0,
        rate REAL NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    if (version >= 2) {
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  // Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  // ---------------- CUSTOMER OPERATIONS ----------------

  Future<int> insertCustomer(Customer customer) async {
    try {
      // Try Firestore first
      if (FirebaseService().isAuthenticated) {
        final docId = await _firestoreService.addCustomer(customer);
        customer.id = int.tryParse(docId); // Store Firestore ID as local ID
      }
    } catch (e) {
      print('Firestore insert failed, using local DB: $e');
    }

    // Always insert to local DB as backup
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    try {
      // Try Firestore first if authenticated
      if (FirebaseService().isAuthenticated) {
        return await _firestoreService.getCustomers();
      }
    } catch (e) {
      print('Firestore query failed, using local DB: $e');
    }

    // Fallback to local DB
    final db = await database;
    final result = await db.query('customers', orderBy: 'id ASC');
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<int> updateCustomer(int id, String newName) async {
    try {
      // Try Firestore first
      if (FirebaseService().isAuthenticated) {
        final customer = Customer(id: id, name: newName);
        await _firestoreService.updateCustomer(id.toString(), customer);
      }
    } catch (e) {
      print('Firestore update failed, using local DB: $e');
    }

    // Always update local DB
    final db = await database;
    return await db.update(
      'customers',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    try {
      // Try Firestore first
      if (FirebaseService().isAuthenticated) {
        await _firestoreService.deleteCustomer(id.toString());
      }
    } catch (e) {
      print('Firestore delete failed, using local DB: $e');
    }

    // Always delete from local DB
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> getCustomerNameById(int id) async {
    final db = await database;
    final result = await db.query(
      'customers',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first['name'] as String;
    }
    return null;
  }

  // ---------------- MILK ENTRY OPERATIONS ----------------

  Future<int> insertMilkEntry(MilkEntry entry) async {
    try {
      // Try Firestore first
      if (FirebaseService().isAuthenticated) {
        final docId = await _firestoreService.addMilkEntry(entry);
        entry.id = int.tryParse(docId); // Store Firestore ID as local ID
      }
    } catch (e) {
      print('Firestore insert failed, using local DB: $e');
    }

    // Always insert to local DB as backup
    final db = await database;

    // Auto-calculate rate and amount
    double rate =
        (Constants.rateConstantA * entry.fat) + Constants.rateConstantB;
    double amount = rate * entry.quantity;

    final data = entry.toMap()
      ..['rate'] = rate
      ..['amount'] = amount;

    return await db.insert('milk_entries', data);
  }

  Future<List<MilkEntry>> getAllMilkEntries() async {
    try {
      // Try Firestore first if authenticated
      if (FirebaseService().isAuthenticated) {
        return await _firestoreService.getMilkEntries();
      }
    } catch (e) {
      print('Firestore query failed, using local DB: $e');
    }

    // Fallback to local DB
    final db = await database;
    final result = await db.query(
      'milk_entries',
      orderBy: 'date DESC, shift ASC',
    );
    return result.map((map) => MilkEntry.fromMap(map)).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'milk_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'shift ASC',
    );
    return result.map((map) => MilkEntry.fromMap(map)).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesByCustomer(int customerId) async {
    final db = await database;
    final result = await db.query(
      'milk_entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date ASC',
    );
    return result.map((map) => MilkEntry.fromMap(map)).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesByCustomerAndRange(
    int customerId,
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'milk_entries',
      where: 'customer_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [customerId, startDate, endDate],
      orderBy: 'date ASC',
    );
    return result.map((map) => MilkEntry.fromMap(map)).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesInRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'milk_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return result.map((map) => MilkEntry.fromMap(map)).toList();
  }

  Future<List<MilkEntry>> getMilkEntries({String? date}) async {
    final db = await database;
    List<Map<String, dynamic>> result;
    if (date != null) {
      result = await db.query(
        'milk_entries',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'shift ASC',
      );
    } else {
      result = await db.query('milk_entries', orderBy: 'date DESC, shift ASC');
    }
    return result.map((map) => MilkEntry.fromMap(map)).toList();
  }

  Future<int> updateMilkEntry(MilkEntry entry) async {
    try {
      // Try Firestore first
      if (FirebaseService().isAuthenticated) {
        await _firestoreService.updateMilkEntry(entry.id.toString(), entry);
      }
    } catch (e) {
      print('Firestore update failed, using local DB: $e');
    }

    // Always update local DB
    final db = await database;

    double rate =
        (Constants.rateConstantA * entry.fat) + Constants.rateConstantB;
    double amount = rate * entry.quantity;

    final data = entry.toMap()
      ..['rate'] = rate
      ..['amount'] = amount;

    return await db.update(
      'milk_entries',
      data,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteMilkEntry(int id) async {
    try {
      // Try Firestore first
      if (FirebaseService().isAuthenticated) {
        await _firestoreService.deleteMilkEntry(id.toString());
      }
    } catch (e) {
      print('Firestore delete failed, using local DB: $e');
    }

    // Always delete from local DB
    final db = await database;
    return await db.delete('milk_entries', where: 'id = ?', whereArgs: [id]);
  }

  // Get all customers who have milk entries for a specific date
  Future<List<Map<String, dynamic>>> getCustomersWithEntriesForDate(
    String date,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT DISTINCT c.id, c.name
      FROM customers c
      INNER JOIN milk_entries me ON c.id = me.customer_id
      WHERE me.date = ?
      ORDER BY c.id ASC
    ''',
      [date],
    );
    return result;
  }

  // Get milk entries for a specific customer on a specific date
  Future<List<MilkEntry>> getMilkEntriesByCustomerAndDate(
    int customerId,
    String date,
  ) async {
    final db = await database;
    final result = await db.query(
      'milk_entries',
      where: 'customer_id = ? AND date = ?',
      whereArgs: [customerId, date],
      orderBy: 'shift ASC',
    );
    return result.map((map) => MilkEntry.fromMap(map)).toList();
  }

  // ---------------- SETTINGS OPERATIONS ----------------

  Future<void> saveSetting(String key, String value) async {
    try {
      // Try Firestore first
      if (FirebaseService().isAuthenticated) {
        await _firestoreService.saveSetting(key, value);
      }
    } catch (e) {
      print('Firestore save setting failed, using local DB: $e');
    }

    // Always save to local DB
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    try {
      // Try Firestore first if authenticated
      if (FirebaseService().isAuthenticated) {
        return await _firestoreService.getSetting(key);
      }
    } catch (e) {
      print('Firestore get setting failed, using local DB: $e');
    }

    // Fallback to local DB
    final db = await database;
    final result = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  // Update customer name (overloaded method)
  Future<int> updateCustomerByObject(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // Delete customer (overloaded method)
  Future<int> deleteCustomerAndResetIds(int id) async {
    final db = await database;
    int result = await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    if (result > 0) {
      await resetCustomerIds();
    }
    return result;
  }

  // Reset customer IDs to sequential after delete
  Future<void> resetCustomerIds() async {
    final db = await database;

    // Disable foreign key constraints
    await db.execute("PRAGMA foreign_keys = OFF");

    // Create temporary table with new sequential IDs
    await db.execute('''
      CREATE TABLE customers_temp (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Insert customers with new IDs
    await db.execute('''
      INSERT INTO customers_temp (name)
      SELECT name FROM customers ORDER BY id ASC
    ''');

    // Update milk_entries with new customer IDs
    await db.execute('''
      UPDATE milk_entries
      SET customer_id = (
        SELECT ct.id
        FROM customers_temp ct
        WHERE ct.name = (SELECT c.name FROM customers c WHERE c.id = milk_entries.customer_id)
      )
    ''');

    // Drop old table and rename temp
    await db.execute('DROP TABLE customers');
    await db.execute('ALTER TABLE customers_temp RENAME TO customers');

    // Re-enable foreign key constraints
    await db.execute("PRAGMA foreign_keys = ON");
  }
}
