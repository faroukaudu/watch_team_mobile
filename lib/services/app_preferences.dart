
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _soundKey = 'watch_team_sound_enabled';
  static const _notificationKey = 'watch_team_notifications_enabled';
  static const _vibrationKey = 'watch_team_vibration_enabled';
  static const _biometricKey = 'watch_team_biometric_enabled';
  static const _locationKey = 'watch_team_location_alerts_enabled';

  static Future<bool> soundEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_soundKey) ?? true;

  static Future<void> setSoundEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_soundKey, value);

  static Future<bool> notificationsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_notificationKey) ?? true;

  static Future<void> setNotificationsEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_notificationKey, value);

  static Future<bool> vibrationEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_vibrationKey) ?? true;

  static Future<void> setVibrationEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_vibrationKey, value);

  static Future<bool> biometricEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_biometricKey) ?? false;

  static Future<void> setBiometricEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_biometricKey, value);

  static Future<bool> locationAlertsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_locationKey) ?? true;

  static Future<void> setLocationAlertsEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_locationKey, value);
}
