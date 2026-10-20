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
        CREATE TABLE IF NOT EXISTS muavinler (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ad TEXT NOT NULL,
          soyad TEXT NOT NULL,
          telefon TEXT NOT NULL,
          tc TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');

      db.execute('''
        CREATE INDEX IF NOT EXISTS idx_muavinler_ad_soyad
        ON muavinler(ad, soyad)
      ''');

      // ŞOFÖRLER TABLOSU
      db.execute('''
        CREATE TABLE IF NOT EXISTS soforler (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ad TEXT NOT NULL,
          soyad TEXT NOT NULL,
          telefon TEXT NOT NULL,
          tc TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');

      // ŞOFÖRLER İNDEXİ
      db.execute('''
        CREATE INDEX IF NOT EXISTS idx_soforler_ad_soyad
        ON soforler(ad, soyad)
      ''');

      // KASA GUNLUK KAYITLARI TABLOSU
      db.execute('''
        CREATE TABLE IF NOT EXISTS kasa_kayitlari (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tarih TEXT NOT NULL UNIQUE, -- YYYY-MM-DD
          aciklama TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');

      // KASA KALEMLERI (GELIR / GIDER DETAYLARI)
      db.execute('''
        CREATE TABLE IF NOT EXISTS kasa_kalemleri (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kasa_id INTEGER NOT NULL,
          tur TEXT NOT NULL, -- 'GELIR' veya 'GIDER'
          baslik TEXT NOT NULL,
          tutar REAL NOT NULL DEFAULT 0.0,
          FOREIGN KEY (kasa_id) REFERENCES kasa_kayitlari(id) ON DELETE CASCADE
        )
      ''');

      db.execute('''
  CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    vehicle_id INTEGER,
    is_important INTEGER NOT NULL DEFAULT 0,
    speak_after_trio INTEGER NOT NULL DEFAULT 0,
    region_entry_only INTEGER NOT NULL DEFAULT 1,
    reminder_at TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (vehicle_id)
      REFERENCES vehicles(id) ON DELETE SET NULL
  )
''');

      db.execute('''
  CREATE INDEX IF NOT EXISTS idx_notes_vehicle
  ON notes(vehicle_id)
''');

      db.execute('''
  CREATE INDEX IF NOT EXISTS idx_notes_reminder
  ON notes(reminder_at)
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

  // --- MUAVİNLER ---

  List<Map<String, Object?>> getAllMuavinler() {
    final result = database.select('''
      SELECT id, ad, soyad, telefon, tc
      FROM muavinler
      ORDER BY ad COLLATE NOCASE, soyad COLLATE NOCASE
    ''');

    return result
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  int insertMuavin({
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    database.execute(
      '''
      INSERT INTO muavinler (ad, soyad, telefon, tc)
      VALUES (?, ?, ?, ?)
      ''',
      [ad, soyad, telefon, tc],
    );

    return database.lastInsertRowId;
  }

  // Belirtilen tarihteki Kasa kaydını getir
  Map<String, Object?>? getKasaByTarih(String tarih) {
    final result = database.select(
      'SELECT * FROM kasa_kayitlari WHERE tarih = ? LIMIT 1',
      [tarih],
    );
    if (result.isEmpty) return null;
    return Map<String, Object?>.from(result.first);
  }

  // Kasa ID'sine ait gelir ve gider kalemlerini getir
  List<Map<String, Object?>> getKasaKalemleri(int kasaId) {
    final result = database.select(
      'SELECT id, tur, baslik, tutar FROM kasa_kalemleri WHERE kasa_id = ?',
      [kasaId],
    );
    return result.map((row) => Map<String, Object?>.from(row)).toList();
  }

  // Günlük Kasayı Kaydet / Güncelle
  void saveKasa({
    required String tarih,
    required String aciklama,
    required List<Map<String, dynamic>> gelirler,
    required List<Map<String, dynamic>> giderler,
  }) {
    database.execute('BEGIN TRANSACTION');
    try {
      final mevcut = getKasaByTarih(tarih);
      int kasaId;

      if (mevcut != null) {
        kasaId = mevcut['id'] as int;
        database.execute(
          'UPDATE kasa_kayitlari SET aciklama = ?, updated_at = datetime(\'now\') WHERE id = ?',
          [aciklama, kasaId],
        );
        database.execute('DELETE FROM kasa_kalemleri WHERE kasa_id = ?', [kasaId]);
      } else {
        database.execute(
          'INSERT INTO kasa_kayitlari (tarih, aciklama) VALUES (?, ?)',
          [tarih, aciklama],
        );
        kasaId = database.lastInsertRowId;
      }

      for (var item in gelirler) {
        database.execute(
          'INSERT INTO kasa_kalemleri (kasa_id, tur, baslik, tutar) VALUES (?, \'GELIR\', ?, ?)',
          [kasaId, item['baslik'], item['tutar']],
        );
      }

      for (var item in giderler) {
        database.execute(
          'INSERT INTO kasa_kalemleri (kasa_id, tur, baslik, tutar) VALUES (?, \'GIDER\', ?, ?)',
          [kasaId, item['baslik'], item['tutar']],
        );
      }

      database.execute('COMMIT');
    } catch (e) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  void updateMuavin({
    required int id,
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    database.execute(
      '''
      UPDATE muavinler
      SET ad = ?,
          soyad = ?,
          telefon = ?,
          tc = ?,
          updated_at = datetime('now')
      WHERE id = ?
      ''',
      [ad, soyad, telefon, tc, id],
    );

    if (database.updatedRows == 0) {
      throw StateError('Muavin kaydı bulunamadı.');
    }
  }

  void deleteMuavin(int id) {
    database.execute(
      'DELETE FROM muavinler WHERE id = ?',
      [id],
    );
  }

  bool muavinTcExists(
      String tc, {
        int? excludeId,
      }) {
    final result = database.select(
      excludeId == null
          ? 'SELECT 1 FROM muavinler WHERE tc = ? LIMIT 1'
          : 'SELECT 1 FROM muavinler WHERE tc = ? AND id != ? LIMIT 1',
      excludeId == null ? [tc] : [tc, excludeId],
    );

    return result.isNotEmpty;
  }



  // --- ŞOFÖRLER ---

  // Bütün şoförleri getir.
  List<Map<String, Object?>> getAllSoforler() {
    final result = database.select('''
      SELECT id, ad, soyad, telefon, tc
      FROM soforler
      ORDER BY ad COLLATE NOCASE, soyad COLLATE NOCASE
    ''');

    return result
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  // Yeni şoför ekle.
  int insertSofor({
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    database.execute(
      '''
      INSERT INTO soforler (ad, soyad, telefon, tc)
      VALUES (?, ?, ?, ?)
      ''',
      [ad, soyad, telefon, tc],
    );

    return database.lastInsertRowId;
  }

  // Mevcut şoförü güncelle.
  void updateSofor({
    required int id,
    required String ad,
    required String soyad,
    required String telefon,
    required String tc,
  }) {
    database.execute(
      '''
      UPDATE soforler
      SET ad = ?,
          soyad = ?,
          telefon = ?,
          tc = ?,
          updated_at = datetime('now')
      WHERE id = ?
      ''',
      [ad, soyad, telefon, tc, id],
    );

    if (database.updatedRows == 0) {
      throw StateError('Şoför kaydı bulunamadı.');
    }
  }

  // Şoförü kalıcı olarak sil.
  void deleteSofor(int id) {
    database.execute(
      'DELETE FROM soforler WHERE id = ?',
      [id],
    );
  }

  // Şoför T.C. kimlik numarasının kullanımda olup olmadığını kontrol et.
  bool soforTcExists(
      String tc, {
        int? excludeId,
      }) {
    final result = database.select(
      excludeId == null
          ? 'SELECT 1 FROM soforler WHERE tc = ? LIMIT 1'
          : 'SELECT 1 FROM soforler WHERE tc = ? AND id != ? LIMIT 1',
      excludeId == null ? [tc] : [tc, excludeId],
    );

    return result.isNotEmpty;
  }

  void close() {
    _database?.dispose();
    _database = null;
  }
}