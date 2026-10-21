
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/Note/Note.dart';

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!Platform.isWindows) {
      throw UnsupportedError(
        'ReminderService yalnızca Windows için yapılandırılmıştır.',
      );
    }

    // Saat dilimi verilerini yükle.
    tz_data.initializeTimeZones();

    // Uygulamanın Türkiye'de kullanılacağı varsayılmıştır.
    // Başka bir saat diliminde kullanılacaksa bu değeri değiştir.
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const windowsSettings = WindowsInitializationSettings(
      appName: 'Araç Takip',
      appUserModelId: 'AracTakip.Desktop',
      guid: '6fbc0f25-1c84-4c98-a03e-8a0dbfc2a561',
    );

    const settings = InitializationSettings(
      windows: windowsSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );

    _initialized = true;
    debugPrint('Hatırlatma servisi başlatıldı.');
  }

  /// Verilen not için tek seferlik hatırlatma planlar.
  ///
  /// [notificationId] her not için sabit ve benzersiz bir int olmalıdır.

  Future<void> scheduleReminder({
    required int notificationId,
    required String title,
    required DateTime reminderAt,
    String? body,
  }) async {
    _ensureInitialized();

    // tarih ve saat bileşenlerini Türkiye yerel saati olarak yorumla.
    final scheduledDate = tz.TZDateTime(
      tz.getLocation('Europe/Istanbul'),
      reminderAt.year,
      reminderAt.month,
      reminderAt.day,
      reminderAt.hour,
      reminderAt.minute,
      reminderAt.second,
    );

    final now = tz.TZDateTime.now(
      tz.getLocation('Europe/Istanbul'),
    );

    // Önce aynı notun eski zamanlamasını kaldır.
    await _notifications.cancel(id: notificationId);

    if (!scheduledDate.isAfter(now)) {
      return;
    }

    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Araç Takip - $title',
      body: body ?? title,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        windows: WindowsNotificationDetails(),
      ),
      payload: notificationId.toString(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

  }


  Future<void> testNotification() async {
    _ensureInitialized();

    await _notifications.show(
      id: 999999,
      title: 'Araç Takip - Test',
      body: 'Windows bildirimi çalışıyor.',
      notificationDetails: const NotificationDetails(
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  Future<void> testScheduledNotification() async {
    _ensureInitialized();

    final scheduledDate = tz.TZDateTime.now(tz.local)
        .add(const Duration(seconds: 5));

    debugPrint('Şimdiki saat: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('Test bildirimi saati: $scheduledDate');

    await _notifications.zonedSchedule(
      id: 999998,
      title: 'Araç Takip - Zamanlama Testi',
      body: 'Beş saniyelik test bildirimi.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        windows: WindowsNotificationDetails(),
      ),
      payload: 'scheduled-test', androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    debugPrint('Beş saniyelik bildirim zamanlandı.');
  }

  /// Notun planlanmış hatırlatmasını iptal eder.
  Future<void> cancelReminder(int notificationId) async {
    _ensureInitialized();
    await _notifications.cancel(id: notificationId);
  }

  /// Tüm planlanmış bildirimleri iptal eder.
  ///
  /// Bunu yalnızca gerçekten bütün hatırlatmaları silmek istediğinde çağır.
  Future<void> cancelAllReminders() async {
    _ensureInitialized();
    await _notifications.cancelAll();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ReminderService.initialize() önce çağrılmalıdır.',
      );
    }
  }
  /// Uygulama açıldığında veritabanındaki notların
  /// gelecekteki hatırlatmalarını yeniden planlar.
  Future<void> rescheduleAll(Iterable<Note> notes) async {
    _ensureInitialized();

    for (final note in notes) {
      final id = note.id;

      if (id == null) continue;

      if (note.reminderAt == null || note.isCompleted) {
        await cancelReminder(id);
        continue;
      }

      if (!note.reminderAt!.isAfter(DateTime.now())) {
        await cancelReminder(id);
        continue;
      }

      await scheduleReminder(
        notificationId: id,
        title: note.title,
        body: note.content.trim().isEmpty
            ? note.title
            : note.content.trim(),
        reminderAt: note.reminderAt!,
      );
    }
  }
}
