
import '../../models/AppSettings/AppSettings.dart';
import '../DatabaseService/DatabaseService.dart';


class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  final DatabaseService _databaseService = DatabaseService.instance;

  AppSettings loadSettings() {
    final rows = _databaseService.database.select(
      'SELECT setting_key, setting_value FROM app_settings',
    );

    final values = <String, String>{};

    for (final row in rows) {
      values[row['setting_key'] as String] =
      row['setting_value'] as String;
    }

    bool readBool(String key, {bool defaultValue = true}) {
      final value = values[key];
      if (value == null) return defaultValue;
      return value == '1';
    }

    return AppSettings(
      voiceEnabled: readBool('voice_enabled'),
      voiceGender: values['voice_gender'] ?? 'female',
      windowsNotificationsEnabled:
      readBool('windows_notifications_enabled'),
      speedNotificationsEnabled:
      readBool('speed_notifications_enabled'),
      ignitionNotificationsEnabled:
      readBool('ignition_notifications_enabled'),
      idleNotificationsEnabled:
      readBool('idle_notifications_enabled'),
      regionNotificationsEnabled:
      readBool('region_notifications_enabled'),
    );
  }

  void saveSettings(AppSettings settings) {
    final now = DateTime.now().toUtc().toIso8601String();

    final values = <String, String>{
      'voice_enabled': settings.voiceEnabled ? '1' : '0',
      'voice_gender': settings.voiceGender,
      'windows_notifications_enabled':
      settings.windowsNotificationsEnabled ? '1' : '0',
      'speed_notifications_enabled':
      settings.speedNotificationsEnabled ? '1' : '0',
      'ignition_notifications_enabled':
      settings.ignitionNotificationsEnabled ? '1' : '0',
      'idle_notifications_enabled':
      settings.idleNotificationsEnabled ? '1' : '0',
      'region_notifications_enabled':
      settings.regionNotificationsEnabled ? '1' : '0',
    };

    final db = _databaseService.database;

    db.execute('BEGIN TRANSACTION');

    try {
      for (final entry in values.entries) {
        db.execute(
          '''
          INSERT INTO app_settings
            (setting_key, setting_value, updated_at)
          VALUES (?, ?, ?)
          ON CONFLICT(setting_key) DO UPDATE SET
            setting_value = excluded.setting_value,
            updated_at = excluded.updated_at
          ''',
          [entry.key, entry.value, now],
        );
      }

      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}
