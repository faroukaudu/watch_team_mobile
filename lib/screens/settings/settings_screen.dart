
import 'package:flutter/material.dart';
import 'package:watch_team/services/app_preferences.dart';
import 'package:watch_team/widgets/security_ui.dart';

import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool loading = true;
  bool sound = true;
  bool notifications = true;
  bool vibration = true;
  bool biometric = false;
  bool locationAlerts = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final values = await Future.wait([
      AppPreferences.soundEnabled(),
      AppPreferences.notificationsEnabled(),
      AppPreferences.vibrationEnabled(),
      AppPreferences.biometricEnabled(),
      AppPreferences.locationAlertsEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      sound = values[0];
      notifications = values[1];
      vibration = values[2];
      biometric = values[3];
      locationAlerts = values[4];
      loading = false;
    });
  }

  Widget toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: SecurityColors.primary.withOpacity(.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: SecurityColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(.52), fontSize: 12),
      ),
      activeColor: SecurityColors.primary,
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecurityPage(
      title: 'Settings',
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: SecurityColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                const Text(
                  'ALERTS & DEVICE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                SecuritySectionCard(
                  child: Column(
                    children: [
                      toggleTile(
                        icon: Icons.volume_up_outlined,
                        title: 'App sound',
                        subtitle: 'Sound for alerts and in-app actions',
                        value: sound,
                        onChanged: (v) {
                          setState(() => sound = v);
                          AppPreferences.setSoundEnabled(v);
                        },
                      ),
                      const Divider(color: SecurityColors.border),
                      toggleTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notifications',
                        subtitle: 'Receive new activity and security alerts',
                        value: notifications,
                        onChanged: (v) {
                          setState(() => notifications = v);
                          AppPreferences.setNotificationsEnabled(v);
                        },
                      ),
                      const Divider(color: SecurityColors.border),
                      toggleTile(
                        icon: Icons.vibration_rounded,
                        title: 'Vibration',
                        subtitle: 'Vibrate for urgent security notifications',
                        value: vibration,
                        onChanged: (v) {
                          setState(() => vibration = v);
                          AppPreferences.setVibrationEnabled(v);
                        },
                      ),
                      const Divider(color: SecurityColors.border),
                      toggleTile(
                        icon: Icons.location_on_outlined,
                        title: 'Location alerts',
                        subtitle: 'Allow post-site and patrol reminders',
                        value: locationAlerts,
                        onChanged: (v) {
                          setState(() => locationAlerts = v);
                          AppPreferences.setLocationAlertsEnabled(v);
                        },
                      ),
                      const Divider(color: SecurityColors.border),
                      toggleTile(
                        icon: Icons.fingerprint_rounded,
                        title: 'Biometric lock',
                        subtitle: 'Preference saved; connect local_auth later',
                        value: biometric,
                        onChanged: (v) {
                          setState(() => biometric = v);
                          AppPreferences.setBiometricEnabled(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'ACCOUNT SECURITY',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                SecuritySectionCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x2229B6F6),
                      child: Icon(Icons.password_rounded,
                          color: SecurityColors.primary),
                    ),
                    title: const Text(
                      'Change password',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Verify the old password before replacing it',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white38),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
