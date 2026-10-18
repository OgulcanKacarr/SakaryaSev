
class AppSettings {
  final bool voiceEnabled;
  final String voiceGender;
  final bool windowsNotificationsEnabled;
  final bool speedNotificationsEnabled;
  final bool ignitionNotificationsEnabled;
  final bool idleNotificationsEnabled;
  final bool regionNotificationsEnabled;

  const AppSettings({
    this.voiceEnabled = true,
    this.voiceGender = 'female',
    this.windowsNotificationsEnabled = true,
    this.speedNotificationsEnabled = true,
    this.ignitionNotificationsEnabled = true,
    this.idleNotificationsEnabled = true,
    this.regionNotificationsEnabled = true,
  });

  AppSettings copyWith({
    bool? voiceEnabled,
    String? voiceGender,
    bool? windowsNotificationsEnabled,
    bool? speedNotificationsEnabled,
    bool? ignitionNotificationsEnabled,
    bool? idleNotificationsEnabled,
    bool? regionNotificationsEnabled,
  }) {
    return AppSettings(
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      voiceGender: voiceGender ?? this.voiceGender,
      windowsNotificationsEnabled:
      windowsNotificationsEnabled ?? this.windowsNotificationsEnabled,
      speedNotificationsEnabled:
      speedNotificationsEnabled ?? this.speedNotificationsEnabled,
      ignitionNotificationsEnabled:
      ignitionNotificationsEnabled ?? this.ignitionNotificationsEnabled,
      idleNotificationsEnabled:
      idleNotificationsEnabled ?? this.idleNotificationsEnabled,
      regionNotificationsEnabled:
      regionNotificationsEnabled ?? this.regionNotificationsEnabled,
    );
  }
}
