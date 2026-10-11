import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Database get database {
    if (_database == null) {
      throw Exception('Database henüz başlatılmadı.');
    }

    return _database!;
  }

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }

    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    final Directory appDirectory = await getApplicationSupportDirectory();

    final String dbPath = join(appDirectory.path, 'sakaryasev.db');

    _database = await openDatabase(
      dbPath,

      version: 3,

      onCreate: _onCreate,

      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trio_vehicle_id TEXT NOT NULL UNIQUE,
        plate TEXT NOT NULL,
        origin TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE regions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        region_id TEXT NOT NULL UNIQUE,
        region_name TEXT NOT NULL,
        voice_enabled INTEGER NOT NULL DEFAULT 1,
        notification_enabled INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE drivers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE vehicle_driver_assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        driver_id INTEGER NOT NULL,
        date TEXT NOT NULL,

        FOREIGN KEY(vehicle_id)
        REFERENCES vehicles(id),

        FOREIGN KEY(driver_id)
        REFERENCES drivers(id)
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {


      await db.execute('''
        CREATE TABLE vehicle_driver_assignments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicle_id INTEGER NOT NULL,
          driver_id INTEGER NOT NULL,
          date TEXT NOT NULL
        );
      ''');
    }
  }

  Future<void> close() async {
    await _database?.close();

    _database = null;
  }
}
