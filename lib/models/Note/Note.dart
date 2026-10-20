class Note {
  final int? id;
  final String title;
  final String content;
  final int? vehicleId;
  final bool isImportant;
  final bool speakAfterTrio;
  final bool regionEntryOnly;
  final DateTime? reminderAt;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? vehiclePlate;

  const Note({
    this.id,
    required this.title,
    required this.content,
    this.vehicleId,
    this.isImportant = false,
    this.speakAfterTrio = false,
    this.regionEntryOnly = true,
    this.reminderAt,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.vehiclePlate,
  });

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      vehicleId: map['vehicle_id'] as int?,
      isImportant: (map['is_important'] as int? ?? 0) == 1,
      speakAfterTrio: (map['speak_after_trio'] as int? ?? 0) == 1,
      regionEntryOnly: (map['region_entry_only'] as int? ?? 1) == 1,
      reminderAt: map['reminder_at'] == null
          ? null
          : DateTime.tryParse(map['reminder_at'] as String),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'] as String),
      vehiclePlate: map['vehicle_plate'] as String?,
    );
  }
}