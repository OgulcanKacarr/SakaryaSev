
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/Vehicle/Vehicle.dart';
import '../DatabaseService/DatabaseService.dart';


class VehicleService {
  VehicleService._();

  static final VehicleService instance = VehicleService._();

  final StreamController<void> _changes =
  StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  void _notifyChanged() {
    _changes.add(null);
  }

  List<Vehicle> getAllVehicles() {
    final result = DatabaseService.instance.database.select(
      'SELECT * FROM vehicles ORDER BY plate COLLATE NOCASE ASC',
    );

    return result
        .map((row) => Vehicle.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  int getVehicleCount() {
    final result = DatabaseService.instance.database.select(
      'SELECT COUNT(*) AS total FROM vehicles',
    );
    return result.first['total'] as int;
  }

  Vehicle? getVehicleByTrioId(String trioVehicleId) {
    final result = DatabaseService.instance.database.select(
      'SELECT * FROM vehicles WHERE trio_vehicle_id = ? LIMIT 1',
      [trioVehicleId],
    );

    if (result.isEmpty) return null;

    return Vehicle.fromMap(
      Map<String, Object?>.from(result.first),
    );
  }

  int addVehicle(Vehicle vehicle) {
    final data = vehicle.toMap();
    final now = DateTime.now().toIso8601String();

    try {
      final statement = DatabaseService.instance.database.prepare('''
        INSERT INTO vehicles (
          plate, trio_vehicle_id, brand, model, year,
          description, is_active, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');

      try {
        statement.execute([
          data['plate'],
          data['trio_vehicle_id'],
          data['brand'],
          data['model'],
          data['year'],
          data['description'],
          data['is_active'],
          now,
          now,
        ]);
      } finally {
        statement.dispose();
      }

      return DatabaseService.instance.database.lastInsertRowId;
    } catch (e) {
      debugPrint('Araç ekleme hatası: $e');
      rethrow;
    }
  }


  void updateVehicle(Vehicle vehicle) {
    if (vehicle.id == null) {
      throw ArgumentError('Güncellenecek aracın ID bilgisi eksik.');
    }

    final data = vehicle.toMap();
    final now = DateTime.now().toIso8601String();

    try {
      debugPrint('Araç güncelleme başladı: ${vehicle.plate}');

      DatabaseService.instance.database.execute(
        '''
      UPDATE vehicles
      SET plate = ?,
          brand = ?,
          model = ?,
          year = ?,
          description = ?,
          is_active = ?,
          updated_at = ?
      WHERE id = ?
      ''',
        [
          data['plate'],
          data['brand'],
          data['model'],
          data['year'],
          data['description'],
          data['is_active'],
          now,
          vehicle.id,
        ],
      );

      debugPrint('Araç güncellendi: ${vehicle.plate}');
    } catch (e, stackTrace) {
      debugPrint('Araç güncelleme hatası: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }


  void deleteVehicle(int id) {
    try {
      DatabaseService.instance.database.execute(
        'DELETE FROM vehicles WHERE id = ?',
        [id],
      );
    } catch (e) {
      debugPrint('Araç silme hatası: $e');
      rethrow;
    }
  }

  /// TRIO olayındaki plakayı ve araç ID'sini bulup kayıtlı araçla eşleştirir.
  void autoMatchTrioEvent(Map<String, dynamic> event) {
    try {
      final violation = _asMap(event['violation']);
      final violationVehicle = _asMap(violation?['vehicle']);

      final alarmRule = _asMap(event['alarmRule']);
      final rule = _asMap(alarmRule?['rule']);
      final ruleVehicle = _asMap(rule?['vehicle']);

      final rawId =
          violationVehicle?['_id'] ?? ruleVehicle?['_id'];
      final trioId = rawId?.toString().trim();

      final summary = event['summary'];
      final plate = summary is String
          ? _extractPlate(summary)
          : null;

      if (trioId == null || trioId.isEmpty) {
        debugPrint('TRIO eşleştirme yapılamadı: araç ID bilgisi bulunamadı.');
        return;
      }

      if (plate == null) {
        debugPrint(
          'TRIO eşleştirme yapılamadı: olay özetinden plaka okunamadı. '
              'TRIO ID: $trioId',
        );
        return;
      }

      final database = DatabaseService.instance.database;

      final rows = database.select(
        'SELECT * FROM vehicles WHERE plate = ? COLLATE NOCASE LIMIT 1',
        [plate],
      );

      if (rows.isEmpty) {
        debugPrint(
          'TRIO plakası uygulamada kayıtlı değil: $plate. '
              'Önce Araçlar sayfasından bu plakayı ekleyin.',
        );
        return;
      }

      final vehicle = Vehicle.fromMap(
        Map<String, Object?>.from(rows.first),
      );

      final currentTrioId = vehicle.trioVehicleId?.trim();

      if (currentTrioId == trioId) {
        return;
      }

      if (currentTrioId != null && currentTrioId.isNotEmpty) {
        debugPrint(
          'TRIO EŞLEŞTİRME UYARISI: $plate plakalı araçta zaten '
              '$currentTrioId kayıtlı. Yeni gelen $trioId otomatik atanmadı.',
        );
        return;
      }

      final idOwner = getVehicleByTrioId(trioId);

      if (idOwner != null && idOwner.plate.toUpperCase() != plate) {
        debugPrint(
          'TRIO EŞLEŞTİRME ÇAKIŞMASI: $trioId ID bilgisi '
              '${idOwner.plate} plakalı araca kayıtlı. $plate ile eşleştirilmedi.',
        );
        return;
      }

      database.execute(
        '''
        UPDATE vehicles
        SET trio_vehicle_id = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          trioId,
          DateTime.now().toIso8601String(),
          vehicle.id,
        ],
      );

      debugPrint('TRIO eşleştirmesi tamamlandı: $plate ↔ $trioId');
      _notifyChanged();
    } catch (e, stackTrace) {
      // Eşleştirme hatası geçerli webhook isteğinin işlenmesini
      // gereksiz yere durdurmasın.
      debugPrint('TRIO otomatik eşleştirme hatası: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String? _extractPlate(String summary) {
    // Örnekler: "54 BB 265 plakalı" ve "54 E 7944 plakalı"
    final normalized = summary.toUpperCase();

    final match = RegExp(
      r'\b(\d{2})\s+([A-Z]{1,3})\s+(\d{2,4})\s+PLAKALI\b',
    ).firstMatch(normalized);

    if (match == null) return null;

    return '${match.group(1)} ${match.group(2)} ${match.group(3)}';
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
