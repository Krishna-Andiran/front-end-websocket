import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:sembast/sembast_io.dart';

import 'package:sembast_web/sembast_web.dart';
import 'package:path_provider/path_provider.dart'; // Only for mobile

class DatabaseService {
  late Database _db;
  late StoreRef<String, Map<String, dynamic>> _store;

  DatabaseService() {
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    if (kIsWeb) {
      // Handle the web case
      var databaseFactory = databaseFactoryWeb; // Use the web factory
      _db = await databaseFactory
          .openDatabase('app_db.db'); // Use a name for IndexedDB
    } else {
      // Handle mobile case
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = '${directory.path}/app_db.db';
      var databaseFactory = databaseFactoryIo;
      _db = await databaseFactory.openDatabase(dbPath);
    }

    _store = stringMapStoreFactory.store('app_data');
  }

  Future<void> storeLastActiveTime(DateTime time) async {
    await _store
        .record('last_active')
        .put(_db, {'time': time.toIso8601String()});
  }

  Future<DateTime?> getLastActiveTime() async {
    final record = await _store.record('last_active').get(_db);
    if (record != null) {
      return DateTime.parse(record['time'] as String);
    }
    return null;
  }

  Database get database => _db;
}
