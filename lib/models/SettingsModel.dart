class SettingsModel {
  bool voiceEnabled;
  bool notificationEnabled;
  String voiceType;

  SettingsModel({
    required this.voiceEnabled,
    required this.notificationEnabled,
    required this.voiceType,
  });

  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      voiceEnabled: true,
      notificationEnabled: true,
      voiceType: "female",
    );
  }
}