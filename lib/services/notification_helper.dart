import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _player = AudioPlayer();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications.initialize(initSettings);
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  static Future<void> playSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.wav'));
    } catch (e) {
      debugPrint('Notification sound failed: $e');
    }
  }

  static Future<void> show({
    required String title,
    required String body,
    bool play = true,
  }) async {
    if (!_ready) await init();

    if (play) {
      await playSound();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'watch_team_alerts',
        'Watch Team Alerts',
        channelDescription: 'Watch Team notification alerts',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }
}
