import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:watch_team/models/guard_reminder.dart';

class ReminderService {
  ReminderService._();

  static const String _storageKey = 'watch_team_guard_reminders_v1';
  static const String _triggeredStorageKey =
      'watch_team_guard_reminder_triggered_v1';

  static const String _channelId = 'watch_team_guard_reminders_v2';
  static const String _channelName = 'Guard Reminders Alarm';
  static const String _channelDescription =
      'Watch Team guard alarms and operational reminders';

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static Timer? _foregroundWatcher;

  static bool _initialized = false;
  static bool _dialogOpen = false;

  static Future<void> init({
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    }

    if (_initialized) {
      _startForegroundWatcher();
      return;
    }

    tz_data.initializeTimeZones();

    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          'watch_team_reminder',
        ),
        enableVibration: true,
      ),
    );

    _initialized = true;

    _startForegroundWatcher();
  }

  static Future<List<GuardReminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <GuardReminder>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <GuardReminder>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => GuardReminder.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    } catch (_) {
      return <GuardReminder>[];
    }
  }

  static Future<void> saveReminders(
      List<GuardReminder> reminders,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(
        reminders.map((item) => item.toJson()).toList(),
      ),
    );
  }

  static Future<void> addReminder(
      GuardReminder reminder,
      ) async {
    final reminders = await loadReminders();

    reminders.removeWhere((item) => item.id == reminder.id);
    reminders.add(reminder);

    await saveReminders(reminders);
    await _clearTriggeredStateFor(reminder.id);

    if (reminder.enabled) {
      await schedule(reminder);
    }
  }

  static Future<void> updateReminder(
      GuardReminder reminder,
      ) async {
    final reminders = await loadReminders();
    final index =
    reminders.indexWhere((item) => item.id == reminder.id);

    if (index == -1) return;

    reminders[index] = reminder;

    await saveReminders(reminders);
    await _notifications.cancel(reminder.id);
    await _clearTriggeredStateFor(reminder.id);

    if (reminder.enabled) {
      await schedule(reminder);
    }
  }

  static Future<void> deleteReminder(
      int reminderId,
      ) async {
    final reminders = await loadReminders();

    reminders.removeWhere((item) => item.id == reminderId);

    await saveReminders(reminders);
    await _notifications.cancel(reminderId);
    await _clearTriggeredStateFor(reminderId);
  }

  static Future<void> setEnabled(
      GuardReminder reminder,
      bool enabled,
      ) async {
    await updateReminder(
      reminder.copyWith(enabled: enabled),
    );
  }

  static Future<void> rescheduleAll() async {
    final reminders = await loadReminders();

    for (final reminder in reminders) {
      await _notifications.cancel(reminder.id);

      if (reminder.enabled) {
        await schedule(reminder);
      }
    }
  }

  static Future<void> schedule(
      GuardReminder reminder,
      ) async {
    if (!_initialized) {
      await init();
    }

    if (!reminder.enabled) return;

    final next = reminder.nextOccurrence();

    if (next == null || !next.isAfter(DateTime.now())) {
      return;
    }

    DateTimeComponents? repeatComponent;

    if (reminder.repeat == 'Daily') {
      repeatComponent = DateTimeComponents.time;
    } else if (reminder.repeat == 'Weekly') {
      repeatComponent = DateTimeComponents.dayOfWeekAndTime;
    }

    await _notifications.zonedSchedule(
      reminder.id,
      '${reminder.service} reminder',
      reminder.title.trim().isNotEmpty
          ? reminder.title.trim()
          : 'Your Watch Team reminder is due now.',
      tz.TZDateTime.from(next, tz.local),
      _notificationDetails(),
      androidScheduleMode:
      AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeatComponent,
      payload: reminder.id.toString(),
    );
  }

  static NotificationDetails _notificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        'watch_team_reminder',
      ),
      enableVibration: true,
      vibrationPattern: Int64List.fromList(
        <int>[0, 700, 300, 700, 300, 1000],
      ),
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'watch_team_reminder.aiff',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static Future<void> testAlarmSound() async {
    if (!_initialized) {
      await init();
    }

    await _notifications.show(
      999999,
      'Watch Team alarm test',
      'Your reminder sound is working.',
      _notificationDetails(),
    );
  }

  static void _startForegroundWatcher() {
    _foregroundWatcher?.cancel();

    _foregroundWatcher = Timer.periodic(
      const Duration(seconds: 1),
          (_) async {
        final now = DateTime.now();
        final reminders = await loadReminders();

        for (final reminder in reminders) {
          if (!reminder.enabled) continue;

          final occurrence =
          _currentOccurrenceForReminder(reminder, now);

          if (occurrence == null) continue;

          final difference =
              now.difference(occurrence).inSeconds;

          // Wide enough to avoid missing the exact second because of
          // timer drift, navigation, rendering, or phone load.
          if (difference < 0 || difference > 90) {
            continue;
          }

          final occurrenceKey =
              '${reminder.id}_${occurrence.millisecondsSinceEpoch}';

          final alreadyTriggered =
          await _wasOccurrenceTriggered(occurrenceKey);

          if (alreadyTriggered) continue;

          await _markOccurrenceTriggered(occurrenceKey);
          await _triggerReminderNow(reminder);

          if (reminder.repeat == 'None') {
            await _disableOneTimeReminder(reminder);
          }

          break;
        }
      },
    );
  }

  static DateTime? _currentOccurrenceForReminder(
      GuardReminder reminder,
      DateTime now,
      ) {
    if (reminder.repeat == 'None') {
      return reminder.scheduledAt;
    }

    if (reminder.repeat == 'Daily') {
      final todayOccurrence = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.scheduledAt.hour,
        reminder.scheduledAt.minute,
      );

      if (todayOccurrence.isBefore(reminder.scheduledAt)) {
        return null;
      }

      return todayOccurrence;
    }

    if (reminder.repeat == 'Weekly') {
      final todayAtReminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.scheduledAt.hour,
        reminder.scheduledAt.minute,
      );

      final daysBack =
          (todayAtReminderTime.weekday -
              reminder.scheduledAt.weekday +
              7) %
              7;

      final occurrence =
      todayAtReminderTime.subtract(
        Duration(days: daysBack),
      );

      if (occurrence.isBefore(reminder.scheduledAt)) {
        return null;
      }

      return occurrence;
    }

    return reminder.scheduledAt;
  }

  static Future<void> _triggerReminderNow(
      GuardReminder reminder,
      ) async {
    await _notifications.show(
      reminder.id,
      '${reminder.service} reminder',
      reminder.title.trim().isNotEmpty
          ? reminder.title.trim()
          : 'Your Watch Team reminder is due now.',
      _notificationDetails(),
      payload: reminder.id.toString(),
    );

    await _showAlarmDialog(reminder);
  }

  static Future<void> _disableOneTimeReminder(
      GuardReminder reminder,
      ) async {
    final reminders = await loadReminders();
    final index =
    reminders.indexWhere((item) => item.id == reminder.id);

    if (index == -1) return;

    reminders[index] =
        reminder.copyWith(enabled: false);

    await saveReminders(reminders);
  }

  static void _onNotificationResponse(
      NotificationResponse response,
      ) {
    final payload = response.payload;

    if (payload == null) return;

    final reminderId = int.tryParse(payload);

    if (reminderId == null) return;

    loadReminders().then((reminders) {
      for (final reminder in reminders) {
        if (reminder.id == reminderId) {
          _showAlarmDialog(reminder);
          break;
        }
      }
    });
  }

  static Future<void> _showAlarmDialog(
      GuardReminder reminder,
      ) async {
    final context = _navigatorKey?.currentContext;

    if (context == null || _dialogOpen) return;

    _dialogOpen = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0B1A29),
            title: Text(
              reminder.title.trim().isNotEmpty
                  ? reminder.title.trim()
                  : 'Reminder due now',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              reminder.note.trim().isNotEmpty
                  ? reminder.note.trim()
                  : reminder.service,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Acknowledge'),
              ),
            ],
          );
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  static Future<bool> _wasOccurrenceTriggered(
      String occurrenceKey,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final triggered =
        prefs.getStringList(_triggeredStorageKey) ??
            <String>[];

    return triggered.contains(occurrenceKey);
  }

  static Future<void> _markOccurrenceTriggered(
      String occurrenceKey,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final triggered =
        prefs.getStringList(_triggeredStorageKey) ??
            <String>[];

    if (!triggered.contains(occurrenceKey)) {
      triggered.add(occurrenceKey);
    }

    // Keep only recent entries.
    if (triggered.length > 200) {
      triggered.removeRange(
        0,
        triggered.length - 200,
      );
    }

    await prefs.setStringList(
      _triggeredStorageKey,
      triggered,
    );
  }

  static Future<void> _clearTriggeredStateFor(
      int reminderId,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final triggered =
        prefs.getStringList(_triggeredStorageKey) ??
            <String>[];

    triggered.removeWhere(
          (item) => item.startsWith('${reminderId}_'),
    );

    await prefs.setStringList(
      _triggeredStorageKey,
      triggered,
    );
  }

  static void dispose() {
    _foregroundWatcher?.cancel();
    _foregroundWatcher = null;
  }
}
