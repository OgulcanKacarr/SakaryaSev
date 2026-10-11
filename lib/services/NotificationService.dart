
import 'package:local_notifier/local_notifier.dart';

class NotificationService {

  Future<void> init() async {
    await localNotifier.setup(
      appName: "Sakaryasev Takip",
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  Future<void> show({
    required String title,
    required String body,
  }) async {

    final notification = LocalNotification(

      title: title,

      body: body,

    );

    await notification.show();

  }

}