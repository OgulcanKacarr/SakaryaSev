import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/Note/Note.dart';
import '../DatabaseService/DatabaseService.dart';

class NoteService {
  NoteService._();

  static final NoteService instance = NoteService._();

  final StreamController<void> _changes =
  StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  void _notifyChanged() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  List<Note> getAllNotes() {
    final rows = DatabaseService.instance.database.select('''
      SELECT n.*, v.plate AS vehicle_plate
      FROM notes n
      LEFT JOIN vehicles v ON v.id = n.vehicle_id
      ORDER BY n.is_important DESC,
               n.is_completed ASC,
               n.created_at DESC
    ''');

    return rows
        .map((row) => Note.fromMap(
      Map<String, Object?>.from(row),
    ))
        .toList();
  }

  List<Note> getRecentNotes({int limit = 5}) {
    final rows = DatabaseService.instance.database.select(
      '''
      SELECT n.*, v.plate AS vehicle_plate
      FROM notes n
      LEFT JOIN vehicles v ON v.id = n.vehicle_id
      ORDER BY n.is_completed ASC,
               n.is_important DESC,
               n.created_at DESC
      LIMIT ?
      ''',
      [limit],
    );

    return rows
        .map((row) => Note.fromMap(
      Map<String, Object?>.from(row),
    ))
        .toList();
  }

  List<Note> getNotesForVehicle(int vehicleId) {
    final rows = DatabaseService.instance.database.select(
      '''
      SELECT n.*, v.plate AS vehicle_plate
      FROM notes n
      LEFT JOIN vehicles v ON v.id = n.vehicle_id
      WHERE n.vehicle_id = ?
      ORDER BY n.created_at DESC
      ''',
      [vehicleId],
    );

    return rows
        .map((row) => Note.fromMap(
      Map<String, Object?>.from(row),
    ))
        .toList();
  }

  List<Note> getSpeakableNotesForVehicle(
      int vehicleId, {
        bool regionEntry = false,
      }) {
    final rows = DatabaseService.instance.database.select(
      '''
      SELECT n.*, v.plate AS vehicle_plate
      FROM notes n
      LEFT JOIN vehicles v ON v.id = n.vehicle_id
      WHERE n.vehicle_id = ?
        AND n.speak_after_trio = 1
        AND n.is_completed = 0
        AND (n.region_entry_only = 0 OR ? = 1)
      ORDER BY n.is_important DESC, n.created_at ASC
      ''',
      [vehicleId, regionEntry ? 1 : 0],
    );

    return rows
        .map((row) => Note.fromMap(
      Map<String, Object?>.from(row),
    ))
        .toList();
  }
  List<Note> getSpeakableNotesForEvent(
      Map<String, dynamic> event, {
        required bool regionEntry,
      }) {
    final dynamic nestedJson = event['json'];

    final Map<String, dynamic> data = nestedJson is Map
        ? Map<String, dynamic>.from(nestedJson)
        : event;

    final dynamic violationValue = data['violation'];
    final dynamic alarmRuleValue = data['alarmRule'];

    final Map violation =
    violationValue is Map ? violationValue : {};

    final Map alarmRule =
    alarmRuleValue is Map ? alarmRuleValue : {};

    final Map violationVehicle = violation['vehicle'] is Map
        ? violation['vehicle'] as Map
        : {};

    final Map rule = alarmRule['rule'] is Map
        ? alarmRule['rule'] as Map
        : {};

    final Map ruleVehicle = rule['vehicle'] is Map
        ? rule['vehicle'] as Map
        : {};

    final rawId =
        violationVehicle['_id'] ?? ruleVehicle['_id'];

    final trioId = rawId?.toString().trim();

    String plate = (violationVehicle['plate'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    if (plate.isEmpty) {
      final summary = data['summary'];

      if (summary is String) {
        final match = RegExp(
          r'(\d{2}\s+[A-ZÇĞİÖŞÜ]{1,3}\s+\d{2,4})\s+plakalı',
          caseSensitive: false,
        ).firstMatch(summary);

        if (match != null) {
          plate = match.group(1)!
              .replaceAll(RegExp(r'\s+'), ' ')
              .toUpperCase();
        }
      }
    }

    final db = DatabaseService.instance.database;

    List<Map<String, Object?>> rows = [];

    if (trioId != null && trioId.isNotEmpty) {
      rows = db.select(
        '''
      SELECT id
      FROM vehicles
      WHERE trio_vehicle_id = ?
      LIMIT 1
      ''',
        [trioId],
      ).map((row) => Map<String, Object?>.from(row)).toList();
    }

    if (rows.isEmpty && plate.isNotEmpty) {
      rows = db.select(
        '''
      SELECT id
      FROM vehicles
      WHERE plate = ? COLLATE NOCASE
      LIMIT 1
      ''',
        [plate],
      ).map((row) => Map<String, Object?>.from(row)).toList();
    }

    if (rows.isEmpty) return [];

    return getSpeakableNotesForVehicle(
      rows.first['id'] as int,
      regionEntry: regionEntry,
    );
  }
  int addNote(Note note) {
    final now = DateTime.now().toIso8601String();

    final db = DatabaseService.instance.database;

    db.execute(
      '''
      INSERT INTO notes (
        title, content, vehicle_id,
        is_important, speak_after_trio,
        region_entry_only, reminder_at,
        is_completed, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        note.title.trim(),
        note.content.trim(),
        note.vehicleId,
        note.isImportant ? 1 : 0,
        note.speakAfterTrio ? 1 : 0,
        note.regionEntryOnly ? 1 : 0,
        note.reminderAt?.toIso8601String(),
        note.isCompleted ? 1 : 0,
        now,
        now,
      ],
    );

    final id = db.lastInsertRowId;
    _notifyChanged();
    return id;
  }

  void updateNote(Note note) {
    if (note.id == null) {
      throw ArgumentError('Güncellenecek notun ID bilgisi eksik.');
    }

    DatabaseService.instance.database.execute(
      '''
      UPDATE notes
      SET title = ?,
          content = ?,
          vehicle_id = ?,
          is_important = ?,
          speak_after_trio = ?,
          region_entry_only = ?,
          reminder_at = ?,
          is_completed = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        note.title.trim(),
        note.content.trim(),
        note.vehicleId,
        note.isImportant ? 1 : 0,
        note.speakAfterTrio ? 1 : 0,
        note.regionEntryOnly ? 1 : 0,
        note.reminderAt?.toIso8601String(),
        note.isCompleted ? 1 : 0,
        DateTime.now().toIso8601String(),
        note.id,
      ],
    );

    _notifyChanged();
  }

  void deleteNote(int id) {
    DatabaseService.instance.database.execute(
      'DELETE FROM notes WHERE id = ?',
      [id],
    );

    _notifyChanged();
  }

  void toggleCompleted(Note note) {
    updateNote(
      Note(
        id: note.id,
        title: note.title,
        content: note.content,
        vehicleId: note.vehicleId,
        isImportant: note.isImportant,
        speakAfterTrio: note.speakAfterTrio,
        regionEntryOnly: note.regionEntryOnly,
        reminderAt: note.reminderAt,
        isCompleted: !note.isCompleted,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        vehiclePlate: note.vehiclePlate,
      ),
    );
  }

  @visibleForTesting
  void dispose() {
    _changes.close();
  }
}