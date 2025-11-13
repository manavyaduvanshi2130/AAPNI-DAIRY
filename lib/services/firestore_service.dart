import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aapni_dairy/models/customer.dart';
import 'package:aapni_dairy/models/milk_entry.dart';
import 'firebase_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final String? _userId = FirebaseService().currentUserId;

  // Collection references
  CollectionReference get _customersCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('customers');
  }

  CollectionReference get _milkEntriesCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('milk_entries');
  }

  CollectionReference get _settingsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('settings');
  }

  // ---------------- CUSTOMER OPERATIONS ----------------

  Future<String> addCustomer(Customer customer) async {
    final docRef = await _customersCollection.add(customer.toMap());
    return docRef.id;
  }

  Future<List<Customer>> getCustomers() async {
    final snapshot = await _customersCollection.orderBy('name').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Customer.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<void> updateCustomer(String customerId, Customer customer) async {
    await _customersCollection.doc(customerId).update(customer.toMap());
  }

  Future<void> deleteCustomer(String customerId) async {
    // Delete customer
    await _customersCollection.doc(customerId).delete();

    // Delete all milk entries for this customer
    final milkEntries = await _milkEntriesCollection
        .where('customer_id', isEqualTo: customerId)
        .get();

    final batch = _firestore.batch();
    for (final doc in milkEntries.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final doc = await _customersCollection.doc(customerId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return Customer.fromMap({...data, 'id': doc.id});
    }
    return null;
  }

  // ---------------- MILK ENTRY OPERATIONS ----------------

  Future<String> addMilkEntry(MilkEntry entry) async {
    final docRef = await _milkEntriesCollection.add(entry.toMap());
    return docRef.id;
  }

  Future<List<MilkEntry>> getMilkEntries() async {
    final snapshot = await _milkEntriesCollection
        .orderBy('date', descending: true)
        .orderBy('shift')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MilkEntry.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesByDate(String date) async {
    final snapshot = await _milkEntriesCollection
        .where('date', isEqualTo: date)
        .orderBy('shift')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MilkEntry.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesByCustomer(String customerId) async {
    final snapshot = await _milkEntriesCollection
        .where('customer_id', isEqualTo: customerId)
        .orderBy('date')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MilkEntry.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesByCustomerAndRange(
    String customerId,
    String startDate,
    String endDate,
  ) async {
    final snapshot = await _milkEntriesCollection
        .where('customer_id', isEqualTo: customerId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MilkEntry.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<List<MilkEntry>> getMilkEntriesInRange(
    String startDate,
    String endDate,
  ) async {
    final snapshot = await _milkEntriesCollection
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MilkEntry.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<void> updateMilkEntry(String entryId, MilkEntry entry) async {
    await _milkEntriesCollection.doc(entryId).update(entry.toMap());
  }

  Future<void> deleteMilkEntry(String entryId) async {
    await _milkEntriesCollection.doc(entryId).delete();
  }

  Future<List<Map<String, dynamic>>> getCustomersWithEntriesForDate(
    String date,
  ) async {
    final snapshot = await _milkEntriesCollection
        .where('date', isEqualTo: date)
        .get();

    final customerIds = snapshot.docs
        .map(
          (doc) =>
              (doc.data() as Map<String, dynamic>)['customer_id'] as String,
        )
        .toSet()
        .toList();

    final customers = <Map<String, dynamic>>[];
    for (final customerId in customerIds) {
      final customer = await getCustomerById(customerId);
      if (customer != null) {
        customers.add({'id': customer.id, 'name': customer.name});
      }
    }

    return customers
      ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
  }

  Future<List<MilkEntry>> getMilkEntriesByCustomerAndDate(
    String customerId,
    String date,
  ) async {
    final snapshot = await _milkEntriesCollection
        .where('customer_id', isEqualTo: customerId)
        .where('date', isEqualTo: date)
        .orderBy('shift')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MilkEntry.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  // ---------------- SETTINGS OPERATIONS ----------------

  Future<void> saveSetting(String key, String value) async {
    await _settingsCollection.doc(key).set({'value': value});
  }

  Future<String?> getSetting(String key) async {
    final doc = await _settingsCollection.doc(key).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['value'] as String;
    }
    return null;
  }

  // ---------------- DATA MIGRATION ----------------

  Future<void> migrateLocalDataToFirestore({
    required List<Customer> customers,
    required List<MilkEntry> milkEntries,
    required Map<String, String> settings,
  }) async {
    final batch = _firestore.batch();

    // Add customers
    for (final customer in customers) {
      final docRef = _customersCollection.doc(customer.id.toString());
      batch.set(docRef, customer.toMap());
    }

    // Add milk entries
    for (final entry in milkEntries) {
      final docRef = _milkEntriesCollection.doc(entry.id.toString());
      batch.set(docRef, entry.toMap());
    }

    // Add settings
    for (final setting in settings.entries) {
      final docRef = _settingsCollection.doc(setting.key);
      batch.set(docRef, {'value': setting.value});
    }

    await batch.commit();
  }
}
