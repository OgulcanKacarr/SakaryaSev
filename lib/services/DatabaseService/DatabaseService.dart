import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Database get database {
    if (_database != null) {
      return _database!;
    }

    if (!Platform.isWindows) {
      throw UnsupportedError(
        'DatabaseService şu anda yalnızca Windows için yapılandırılmıştır.',
      );
    }

    final appData = Platform.environment['LOCALAPPDATA'];

    if (appData == null || appData.isEmpty) {
      throw StateError('Windows LOCALAPPDATA dizini bulunamadı.');
    }

    final directory = Directory(p.join(appData, 'SakaryaSEV'));

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final dbPath = p.join(directory.path, 'sakaryasev.db');

    final db = sqlite3.open(dbPath);

    try {
      db.execute('PRAGMA foreign_keys = ON');

      db.execute('''
        CREATE TABLE IF NOT EXISTS vehicles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plate TEXT NOT NULL COLLATE NOCASE UNIQUE,
          trio_vehicle_id TEXT UNIQUE,
          brand TEXT,
          model TEXT,
          year INTEGER,
          description TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      db.execute('''
        CREATE INDEX IF NOT EXISTS idx_vehicles_trio_id
        ON vehicles(trio_vehicle_id)
      ''');


      db.execute('''
  CREATE TABLE IF NOT EXISTS app_settings (
    setting_key TEXT PRIMARY KEY,
    setting_value TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
''');

      db.execute('''
  INSERT OR IGNORE INTO app_settings
    (setting_key, setting_value, updated_at)
  VALUES
    ('voice_enabled', '1', datetime('now')),
    ('voice_gender', 'female', datetime('now')),
    ('windows_notifications_enabled', '1', datetime('now')),
    ('speed_notifications_enabled', '1', datetime('now')),
    ('ignition_notifications_enabled', '1', datetime('now')),
    ('idle_notifications_enabled', '1', datetime('now')),
    ('region_notifications_enabled', '1', datetime('now'))
''');
      
      _database = db;

      debugPrint('SakaryaSEV veritabanı hazır: $dbPath');

      return db;
    } catch (_) {
      db.dispose();
      rethrow;
    }
  }

  int getVehicleCount() {
    final result = database.select('SELECT COUNT(*) AS total FROM vehicles');

    return result.first['total'] as int;
  }

  void close() {
    _database?.dispose();
    _database = null;
  }
}
