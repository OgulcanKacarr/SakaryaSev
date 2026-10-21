import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/Note/Note.dart';
import '../../../models/Vehicle/Vehicle.dart';
import '../../../services/NoteService/NoteService.dart';
import '../../../services/ReminderService/ReminderService.dart';
import '../../../services/VehicleService/VehicleService.dart';


class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteService _notes = NoteService.instance;
  final VehicleService _vehicles = VehicleService.instance;

  late final StreamSubscription<void> _subscription;

  List<Note> notes = [];
  List<Vehicle> vehicles = [];
  String searchText = '';
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();

    _subscription = _notes.changes.listen((_) => _load());
    _load();
  }

  void _load() {
    try {
      final loadedNotes = _notes.getAllNotes();
      final loadedVehicles = _vehicles.getAllVehicles();

      if (!mounted) return;

      setState(() {
        notes = loadedNotes;
        vehicles = loadedVehicles;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Notlar yüklenemedi: $e';
      });
    }
  }

  List<Note> get filteredNotes {
    final query = searchText.trim().toLowerCase();

    if (query.isEmpty) return notes;

    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          (note.vehiclePlate ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openEditor({Note? note}) async {

    final titleController = TextEditingController(
      text: note?.title ?? '',
    );
    final contentController = TextEditingController(
      text: note?.content ?? '',
    );

    int? vehicleId = note?.vehicleId;
    bool important = note?.isImportant ?? false;
    bool speakAfterTrio = note?.speakAfterTrio ?? false;
    bool regionEntryOnly = note?.regionEntryOnly ?? true;
    bool reminderEnabled = note?.reminderAt != null;

    DateTime reminderDate =
        note?.reminderAt ?? DateTime.now().add(const Duration(hours: 1));

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(note == null ? 'Yeni Not' : 'Notu Düzenle'),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Not başlığı',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Not içeriği',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int?>(
                          value: vehicleId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'İlgili araç (isteğe bağlı)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Araç bağlantısı yok'),
                            ),
                            ...vehicles.map(
                                  (vehicle) => DropdownMenuItem<int?>(
                                value: vehicle.id,
                                child: Text(vehicle.plate),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() => vehicleId = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Önemli not'),
                          value: important,
                          onChanged: (value) {
                            setDialogState(() => important = value);
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('TRIO olayından sonra seslendir'),
                          subtitle: const Text(
                            'Bağlı araç için gelen olay okunduktan sonra '
                                'bu not da okunur.',
                          ),
                          value: speakAfterTrio,
                          onChanged: (value) {
                            setDialogState(() {
                              speakAfterTrio = value;
                            });
                          },
                        ),
                        if (speakAfterTrio) ...[
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Yalnızca bölgeye girişte seslendir',
                            ),
                            value: regionEntryOnly,
                            onChanged: (value) {
                              setDialogState(() {
                                regionEntryOnly = value ?? true;
                              });
                            },
                          ),
                          if (vehicleId == null)
                            const Text(
                              'Seslendirme için önce bir araç seçmelisin.',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Saatli hatırlatma'),
                          subtitle: Text(
                            reminderEnabled
                                ? '${_formatDate(reminderDate)} '
                                '${_formatTime(reminderDate)}'
                                : 'İsteğe bağlı tarih ve saat',
                          ),
                          value: reminderEnabled,
                          onChanged: (value) {
                            setDialogState(() {
                              reminderEnabled = value;
                            });
                          },
                        ),
                        if (reminderEnabled)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Tarih ve saat seç'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: reminderDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );

                              if (date == null || !context.mounted) return;

                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  reminderDate,
                                ),
                              );

                              if (time == null) return;

                              setDialogState(() {
                                reminderDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('İptal'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();

                      if (title.isEmpty || content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Başlık ve not içeriği zorunludur.',
                            ),
                          ),
                        );
                        return;
                      }

                      if (speakAfterTrio && vehicleId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Seslendirme için ilgili aracı seçmelisin.',
                            ),
                          ),
                        );
                        return;
                      }

                      final updatedNote = Note(
                        id: note?.id,
                        title: title,
                        content: content,
                        vehicleId: vehicleId,
                        isImportant: important,
                        speakAfterTrio: speakAfterTrio,
                        regionEntryOnly: regionEntryOnly,
                        reminderAt:
                        reminderEnabled ? reminderDate : null,
                        isCompleted: note?.isCompleted ?? false,
                        createdAt: note?.createdAt,
                      );

                      try {
                        if (note == null) {
                          _notes.addNote(updatedNote);
                        } else {
                          _notes.updateNote(updatedNote);
                        }

                        Navigator.pop(dialogContext);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Not kaydedilemedi: $e')),
                        );
                      }
                    },
                    child: const Text('Kaydet'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      contentController.dispose();
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = filteredNotes;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Notlar',style: TextStyle(color: Colors.greenAccent,fontWeight: FontWeight.bold),),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Not'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Not, içerik veya plaka ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchText = value);
              },
            ),
            const SizedBox(height: 20),
            if (loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Expanded(
                child: Center(child: Text(error!)),
              )
            else if (visibleNotes.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Henüz not eklenmemiş.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: visibleNotes.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = visibleNotes[index];

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Icon(
                            note.isCompleted
                                ? Icons.task_alt
                                : note.isImportant
                                ? Icons.star
                                : note.vehicleId != null
                                ? Icons.directions_bus
                                : Icons.sticky_note_2_outlined,
                            color: note.isCompleted
                                ? Colors.green
                                : note.isImportant
                                ? Colors.orange
                                : null,
                          ),
                          title: Text(
                            note.title,
                            style: TextStyle(
                              decoration: note.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(note.content),
                                const SizedBox(height: 6),
                                if (note.vehiclePlate != null)
                                  Text('Araç: ${note.vehiclePlate}'),
                                if (note.reminderAt != null)
                                  Text(
                                    'Hatırlatma: '
                                        '${_formatDate(note.reminderAt!)} '
                                        '${_formatTime(note.reminderAt!)}',
                                  ),
                                if (note.speakAfterTrio)
                                  const Text('TRIO sonrası seslendirme açık'),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _openEditor(note: note);
                                  break;
                                case 'complete':
                                  _notes.toggleCompleted(note);
                                  break;
                                case 'delete':
                                  _confirmDelete(note);
                                  break;
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Düzenle'),
                              ),
                              PopupMenuItem(
                                value: 'complete',
                                child: Text(
                                  note.isCompleted
                                      ? 'Tamamlanmadı işaretle'
                                      : 'Tamamlandı işaretle',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Sil'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not silinsin mi?'),
        content: Text('"${note.title}" notu silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && note.id != null) {
      _notes.deleteNote(note.id!);
    }
  }
}