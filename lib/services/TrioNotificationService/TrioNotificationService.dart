
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

import '../../models/AppSettings/AppSettings.dart';
import '../SettingsService/SettingsService.dart';
import '../SpeechService/SpeechService.dart';

enum TrioEventType {
  speed,
  ignition,
  idle,
  region,
}

class TrioNotificationService {
  TrioNotificationService._();

  static final TrioNotificationService instance =
  TrioNotificationService._();

  bool _notifierInitialized = false;

  Future<void> _initializeNotifier() async {
    if (_notifierInitialized || !Platform.isWindows) return;

    await localNotifier.setup(appName: 'Araç Takip');
    _notifierInitialized = true;
  }

  Future<void> handleEvent(Map<String, dynamic> receivedEvent) async {
    try {
      // Doğrudan TRIO içeriğini ve { "json": {...} } yapısını destekle.
      final dynamic nestedJson = receivedEvent['json'];

      final Map<String, dynamic> event = nestedJson is Map
          ? Map<String, dynamic>.from(nestedJson)
          : receivedEvent;

      final TrioEventType? type = _detectEventType(event);

      if (type == null) {
        debugPrint('TRIO bildirimi: Olay türü tanınamadı.');
        return;
      }

      final AppSettings settings = SettingsService.instance.loadSettings();

      if (!_isEventEnabled(type, settings)) {
        debugPrint('TRIO bildirimi: Olay türü ayarlardan kapatılmış.');
        return;
      }

      final String message = _buildMessage(event, type);
      if (message.trim().isEmpty) return;

      // Ses ve Windows bildirimi birbirinden bağımsızdır.
      if (settings.voiceEnabled) {
        try {
          await SpeechService.instance.speak(
            message,
            voiceGender: settings.voiceGender,
          );
        } catch (e) {
          // Ses başarısız olsa da Windows bildirimi gösterilmeye devam eder.
          debugPrint('TRIO seslendirme yapılamadı: $e');
        }
      }

      if (settings.windowsNotificationsEnabled && Platform.isWindows) {
        try {
          await _showWindowsNotification(message);
        } catch (e) {
          debugPrint('Windows bildirimi gösterilemedi: $e');
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

  String _buildMessage(Map<String, dynamic> event, TrioEventType type) {
    final dynamic summary = event['summary'];

    // TRIO özet gönderiyorsa metni aynen koru.
    if (summary is String && summary.trim().isNotEmpty) {
      return summary.trim();
    }

    final dynamic violation = event['violation'];

    String plate = 'Bilinmeyen araç';

    if (violation is Map) {
      final dynamic vehicle = violation['vehicle'];

      if (vehicle is Map && vehicle['plate'] != null) {
        plate = vehicle['plate'].toString();
      }
    }

    switch (type) {
      case TrioEventType.speed:
        return '$plate plakalı araçta hız ihlali tespit edildi.';
      case TrioEventType.ignition:
        return '$plate plakalı araçta kontak olayı tespit edildi.';
      case TrioEventType.idle:
        return '$plate plakalı araçta rölanti olayı tespit edildi.';
      case TrioEventType.region:
        return '$plate plakalı araçta bölge olayı tespit edildi.';
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
