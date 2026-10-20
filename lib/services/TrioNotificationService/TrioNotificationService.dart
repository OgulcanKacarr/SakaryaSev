
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

import '../../models/AppSettings/AppSettings.dart';
import '../NoteService/NoteService.dart';
import '../SettingsService/SettingsService.dart';
import '../SpeechService/SpeechService.dart';

enum TrioEventType {
  speed,
  ignition,
  idle,
  region,
}

class TrioDashboardEvent {
  final String message;
  final TrioEventType type;
  final DateTime receivedAt;

  const TrioDashboardEvent({
    required this.message,
    required this.type,
    required this.receivedAt,
  });

  String get typeLabel {
    switch (type) {
      case TrioEventType.speed:
        return 'Hız ihlali';
      case TrioEventType.ignition:
        return 'Kontak';
      case TrioEventType.idle:
        return 'Rölanti';
      case TrioEventType.region:
        return 'Bölge hareketi';
    }
  }

  String get plate {
    final match = RegExp(
      r'^(\d{2}\s+[A-ZÇĞİÖŞÜ]{1,3}\s+\d{2,4})',
      caseSensitive: false,
    ).firstMatch(message);

    return match?.group(1) ?? 'Plaka bilinmiyor';
  }
}

class TrioNotificationService {
  TrioNotificationService._();

  static final TrioNotificationService instance =
  TrioNotificationService._();

  bool _notifierInitialized = false;

  final ValueNotifier<List<TrioDashboardEvent>> dashboardEvents =
  ValueNotifier<List<TrioDashboardEvent>>([]);

  void _addDashboardEvent(
      String message,
      TrioEventType type,
      ) {
    final event = TrioDashboardEvent(
      message: message,
      type: type,
      receivedAt: DateTime.now(),
    );

    dashboardEvents.value = [
      event,
      ...dashboardEvents.value,
    ].take(100).toList();
  }

  Future<void> _initializeNotifier() async {
    if (_notifierInitialized || !Platform.isWindows) return;

    await localNotifier.setup(appName: 'Araç Takip');
    _notifierInitialized = true;
  }


  Future<void> handleEvent(Map<String, dynamic> receivedEvent) async {
    try {
      final dynamic nestedJson = receivedEvent['json'];

      final Map<String, dynamic> event = nestedJson is Map
          ? Map<String, dynamic>.from(nestedJson)
          : receivedEvent;

      final TrioEventType? type = _detectEventType(event);

      if (type == null) {
        debugPrint('TRIO bildirimi: Olay türü tanınamadı.');
        return;
      }

      final AppSettings settings =
      SettingsService.instance.loadSettings();

      if (!_isEventEnabled(type, settings)) {
        debugPrint('TRIO bildirimi: Olay türü ayarlardan kapatılmış.');
        return;
      }

      // Sesli okunacak kısa metni oluştur.
      final String message = _buildMessage(event, type);

      if (message.trim().isEmpty) return;
      _addDashboardEvent(message, type);
      // 1. ÖNCE WINDOWS BİLDİRİMİ
      if (settings.windowsNotificationsEnabled &&
          Platform.isWindows) {
        try {
          await _showWindowsNotification(message);
        } catch (e) {
          debugPrint('Windows bildirimi gösterilemedi: $e');
        }
      }

      // 2. SONRA SESLİ OKUMA
      if (settings.voiceEnabled) {
        try {
          // Önce normal TRIO bildirimi okunur.
          await SpeechService.instance.speak(
            message,
            voiceGender: settings.voiceGender,
          );

          // Bölge olayının giriş mi çıkış mı olduğunu belirle.
          bool regionEntry = false;

          if (type == TrioEventType.region) {
            final dynamic alarmRuleValue = event['alarmRule'];

            final Map alarmRule = alarmRuleValue is Map
                ? alarmRuleValue
                : {};

            final dynamic ruleValue = alarmRule['rule'];

            final Map rule = ruleValue is Map ? ruleValue : {};

            final dynamic regionValue = rule['region'];

            final Map region = regionValue is Map ? regionValue : {};

            final transition =
            (region['transition'] ?? '').toString().toUpperCase();

            regionEntry = transition != 'EXIT';
          }

          // Ardından yalnızca bu araca bağlı, seslendirmesi açık
          // notları sırayla oku.
          final notes = NoteService.instance.getSpeakableNotesForEvent(
            event,
            regionEntry: regionEntry,
          );

          for (final note in notes) {
            try {
              await SpeechService.instance.speak(
                '${note.title}. ${note.content}',
                voiceGender: settings.voiceGender,
              );
            } catch (e) {
              debugPrint(
                'Not seslendirilemedi (${note.title}): $e',
              );
            }
          }
        } catch (e, stackTrace) {
          debugPrint('TRIO seslendirme yapılamadı: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('TRIO bildirim servisi hatası: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }


  TrioEventType? _detectEventType(Map<String, dynamic> event) {
    final dynamic alarmRule = event['alarmRule'];
    final dynamic violation = event['violation'];

    if (alarmRule is! Map || violation is! Map) return null;

    final dynamic rule = alarmRule['rule'];
    if (rule is! Map) return null;

    if (rule['region'] != null) {
      return TrioEventType.region;
    }

    final dynamic threshold = rule['threshold'];
    if (threshold is Map && threshold['speed'] != null) {
      return TrioEventType.speed;
    }

    final dynamic ruleStatus = rule['status'];
    final dynamic violationStatus = violation['status'];

    if (ruleStatus is Map && violationStatus is Map) {
      if (ruleStatus['ignition'] != null &&
          violationStatus['ignition'] != null) {
        return TrioEventType.ignition;
      }

      if (ruleStatus['idle'] != null &&
          violationStatus['idle'] != null) {
        return TrioEventType.idle;
      }
    }

    return null;
  }

  bool _isEventEnabled(TrioEventType type, AppSettings settings) {
    switch (type) {
      case TrioEventType.speed:
        return settings.speedNotificationsEnabled;
      case TrioEventType.ignition:
        return settings.ignitionNotificationsEnabled;
      case TrioEventType.idle:
        return settings.idleNotificationsEnabled;
      case TrioEventType.region:
        return settings.regionNotificationsEnabled;
    }
  }


  String _buildMessage(
      Map<String, dynamic> event,
      TrioEventType type,
      ) {
    // TRIO bazen olayı {"json": {...}} içinde gönderiyor.
    final dynamic nestedJson = event['json'];

    final Map<String, dynamic> data = nestedJson is Map
        ? Map<String, dynamic>.from(nestedJson)
        : event;

    final dynamic violationValue = data['violation'];
    final dynamic alarmRuleValue = data['alarmRule'];

    final Map<dynamic, dynamic> violation =
    violationValue is Map ? violationValue : {};

    final Map<dynamic, dynamic> alarmRule =
    alarmRuleValue is Map ? alarmRuleValue : {};

    final dynamic vehicleValue = violation['vehicle'];
    final Map<dynamic, dynamic> vehicle =
    vehicleValue is Map ? vehicleValue : {};

    final dynamic ruleValue = alarmRule['rule'];
    final Map<dynamic, dynamic> rule =
    ruleValue is Map ? ruleValue : {};

    // Plakayı önce araç bilgisinden, sonra summary içinden al.
    String plate = '';

    if (vehicle['plate'] != null) {
      plate = vehicle['plate'].toString().trim();
    }

    final dynamic summaryValue = data['summary'];
    final String summary =
    summaryValue is String ? summaryValue : '';

    if (plate.isEmpty) {
      final RegExpMatch? match = RegExp(
        r'(\d{2}\s+[A-ZÇĞİÖŞÜ]{1,3}\s+\d{2,4})\s+plakalı araç',
        caseSensitive: false,
      ).firstMatch(summary);

      if (match != null) {
        plate = match.group(1)!.trim();
      }
    }

    if (plate.isEmpty) {
      plate = 'Plakası bilinmeyen';
    }

    switch (type) {
      case TrioEventType.region:
        final dynamic regionValue = violation['region'];
        final Map<dynamic, dynamic> region =
        regionValue is Map ? regionValue : {};

        String regionName =
        (region['label'] ?? region['name'] ?? '').toString().trim();

        // Bölge adı olayda yoksa kuraldan kontrol et.
        if (regionName.isEmpty) {
          final dynamic ruleRegionValue = rule['region'];
          final Map<dynamic, dynamic> ruleRegion =
          ruleRegionValue is Map ? ruleRegionValue : {};

          regionName = (ruleRegion['label'] ??
              ruleRegion['name'] ??
              ruleRegion['title'] ??
              '')
              .toString()
              .trim();
        }

        final dynamic ruleRegionValue = rule['region'];
        final Map<dynamic, dynamic> ruleRegion =
        ruleRegionValue is Map ? ruleRegionValue : {};

        final String transition =
        (ruleRegion['transition'] ?? '').toString().toUpperCase();

        if (regionName.isEmpty) {
          return '$plate plakalı araçta bölge ihlali oluşmuştur.';
        }

        if (transition == 'EXIT') {
          return '$plate plakalı araç $regionName bölgesinden çıkmıştır.';
        }

        return '$plate plakalı araç $regionName bölgesine girmiştir.';


      case TrioEventType.speed:
        final dynamic measurementValue = violation['measurement'];
        final Map<dynamic, dynamic> measurement =
        measurementValue is Map ? measurementValue : {};

        final dynamic thresholdValue = rule['threshold'];
        final Map<dynamic, dynamic> threshold =
        thresholdValue is Map ? thresholdValue : {};

        final dynamic speedValue = threshold['speed'];
        final Map<dynamic, dynamic> speedRule =
        speedValue is Map ? speedValue : {};

        final dynamic latestValue = speedRule['latest'];
        final Map<dynamic, dynamic> latest =
        latestValue is Map ? latestValue : {};

        final dynamic limitValue = latest['limit'];
        final Map<dynamic, dynamic> limit =
        limitValue is Map ? limitValue : {};

        final dynamic actualSpeed = measurement['speed'];
        final dynamic speedLimit = limit['moreThan'];

        if (actualSpeed != null && speedLimit != null) {
          return '$plate plakalı araç, 2 dakika boyunca $speedLimit kilometre hız sınırını aşmıştır.';
        }

        return '$plate plakalı araçta hız ihlali tespit edilmiştir.';


      case TrioEventType.ignition:
        final dynamic statusValue = violation['status'];
        final Map<dynamic, dynamic> status =
        statusValue is Map ? statusValue : {};

        final String ignition =
        (status['ignition'] ?? '').toString().toUpperCase();

        if (ignition == 'OFF') {
          return '$plate plakalı aracın kontağı kapanmıştır.';
        }

        return '$plate plakalı araç kontak açmıştır.';

      case TrioEventType.idle:
        final dynamic statusValue = violation['status'];
        final Map<dynamic, dynamic> status =
        statusValue is Map ? statusValue : {};

        final dynamic idle = status['idle'];

        if (idle == false) {
          return '$plate plakalı araç rölantiden çıkmıştır.';
        }

        return '$plate plakalı araç rölantide çalışmaya başlamıştır.';
    }
  }


  Future<void> _showWindowsNotification(String message) async {
    if (!Platform.isWindows) return;

    await _initializeNotifier();

    final LocalNotification notification = LocalNotification(
      title: 'Araç Takip - TRIO',
      body: message,
    );

    notification.show();
  }
}
