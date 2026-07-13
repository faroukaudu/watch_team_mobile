
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/screens/settings/settings_screen.dart';
import 'package:watch_team/screens/support/chat_support_screen.dart';
import 'package:watch_team/screens/support/email_support_screen.dart';
import 'package:watch_team/screens/support/support_center_screen.dart';
import 'package:watch_team/widgets/security_ui.dart';

class SecurityDrawer extends StatefulWidget {
  final VoidCallback onHome;
  final VoidCallback onSelectCompany;
  final Future<void> Function() onLogout;

  const SecurityDrawer({
    super.key,
    required this.onHome,
    required this.onSelectCompany,
    required this.onLogout,
  });

  @override
  State<SecurityDrawer> createState() => _SecurityDrawerState();
}

class _SecurityDrawerState extends State<SecurityDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Animation<double> itemAnimation(int index) {
    final start = (0.05 + index * .045).clamp(0.0, .78);
    return CurvedAnimation(
      parent: animationController,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
  }

  Widget animatedItem(int index, Widget child) {
    final animation = itemAnimation(index);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-.28, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  void push(Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> feedback() async {
    final info = await PackageInfo.fromPlatform();
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=${info.packageName}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the Play Store')),
      );
    }
  }

  Future<void> shareApp() async {
    final info = await PackageInfo.fromPlatform();
    final url =
        'https://play.google.com/store/apps/details?id=${info.packageName}';
    await Share.share(
      'Protect, report and coordinate with Watch Team.\n$url',
      subject: 'Watch Team Security App',
    );
  }

  Future<void> showVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SecurityColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.verified_user_outlined,
          color: SecurityColors.primary,
          size: 44,
        ),
        title: const Text(
          'Watch Team',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Version ${info.version}\nBuild ${info.buildNumber}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> showAbout() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: SecurityColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .82,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0E2941), Color(0xFF07111C)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: SecurityColors.cyan, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'About Watch Team',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: const Text(
                    r'''Watch Team is a security operations platform designed to connect guards, supervisors, company administrators, clients, and platform administrators in one organized digital environment. The application supports the daily work of security personnel by making information easier to capture, verify, share, and review. Instead of relying only on paper notebooks, telephone calls, and disconnected messaging groups, Watch Team provides a structured place for reports, attendance, post-site activities, alerts, patrol information, schedules, and operational communication.

The mobile application is built around the real activities performed by guards. A guard can sign in securely, select an assigned company or post site, view current duties, check schedules, record attendance, submit reports, attach photographs or video, add a signature, receive notifications, review dispatch instructions, and communicate with authorized personnel. Each feature is intended to improve accountability without making the guard’s workflow unnecessarily complicated.

Security work depends on accurate timing and accurate location. Watch Team therefore supports check-in, time-clock activity, location-aware operations, and post-site selection. These tools help a company understand who is working, where the person is assigned, and what activities have been completed. Location information should always be used responsibly and according to company policy, applicable law, and the permissions granted by the user’s device.

Reports are a central part of the platform. Administrators can create report templates that match the needs of different customers and sites. Guards complete those templates from the mobile application. The report may include text, dates, numbers, selections, checkboxes, signatures, images, video, audio, and other evidence. The platform keeps the internal field keys suitable for reliable data processing while displaying clear human-readable labels to users.

Code Red reporting is intended for urgent situations. When a report category is configured as Code Red, the platform can immediately notify one or more recipients assigned to the selected post site. The report can include a secure public viewing link and important details such as the guard, company, site, submission time, and report title. Code Red should be used only when immediate attention is justified, because repeated or inappropriate emergency notifications can reduce the effectiveness of real alerts.

Site tours, checkpoints, QR codes, and NFC features help document patrol activity. These tools can confirm that a guard reached a required point and completed an expected action. They do not replace professional judgment. A guard must remain aware of surroundings, follow post orders, observe safety requirements, and contact emergency services or supervisors when conditions require action beyond the application.

Scheduling tools allow guards to review shifts, open opportunities, availability, approved assignments, and time-off activity. The objective is to reduce confusion and provide a more consistent record of operational decisions. A displayed schedule remains subject to company policies and supervisor instructions. Guards should report conflicts promptly instead of assuming that an unconfirmed change has been approved.

Communication features are designed for professional operational use. Chat Support connects the guard to company Super Admins and Platform Admins. Role badges help the guard understand who is participating in the conversation. Messages may become part of the company’s operational record, so users should communicate clearly, respectfully, and without sharing unnecessary sensitive information.

Email Support opens the device email application with the dedicated support address already selected. This option is useful when a user needs to provide a longer explanation or information that is better handled outside real-time chat. Users should avoid emailing passwords, OTP codes, private keys, or other authentication secrets. Watch Team support should never ask a user to reveal a password.

Authentication is protected through account credentials and password-reset verification. Guards can request a one-time password through the registered email address and then create a new password. Strong passwords should be unique, difficult to guess, and different from passwords used on other services. Users should not share accounts. When several test accounts use the same credentials, the application may ask the tester to choose the correct account before continuing.

Notifications help users respond to new operational activity. The Settings screen allows the user to control sound, notifications, vibration, and selected preferences. Turning off a device notification does not cancel the underlying responsibility to review schedules, reports, or post instructions. Some emergency communication may also be delivered through email, telephone, SMS, or another company-approved channel.

Watch Team values a clear separation of permissions. Guards should see the information required for their assigned duties. Company administrators manage their own organization, guards, sites, reports, schedules, and recipients. Platform administrators maintain the overall service. Clients may receive access limited to their authorized company or post site. Permission rules should be reviewed as the platform grows.

Data quality matters. A report should be factual, complete, and written as soon as reasonably possible after an event. Users should distinguish direct observations from assumptions, quote witnesses accurately, record times carefully, and avoid language that could be misleading. Images and video should be relevant to the report and captured in a lawful, safe, and professional manner.

The application’s visual design uses dark security-themed surfaces, high-contrast controls, clear icons, and focused status colors. Blue and cyan indicate standard secure actions, green communicates success or availability, amber indicates caution, and red is reserved for destructive actions or urgent Code Red activity. Animation is used to guide attention rather than distract from operational tasks.

The animated navigation drawer provides quick access to the Home dashboard, assigned companies or post sites, settings, support, feedback, sharing, application information, and logout. Menu items appear with a brief staggered slide and fade when the drawer opens. The header identifies the active guard and presents the Watch Team shield as a visual reminder that the application is part of a controlled security environment.

Home returns the user to the primary operational dashboard. Select Company opens the existing company or post-site selection experience. Settings manages user preferences and password changes. Chat Support provides direct conversations with authorized administrators. Email Support prepares a message to the dedicated support mailbox. Support Center offers common guidance. Feedback opens the application listing for a review. Share App launches the device sharing menu.

The application version dialog reads the version and build number configured for the installed application. This information helps support teams understand which release a user is running. When reporting a technical issue, users should include the app version, device model, operating-system version, the approximate time of the problem, and the steps that produced it.

Watch Team is not a replacement for emergency services, law enforcement, medical assistance, fire response, or established company emergency procedures. In an immediate threat, users must follow their training, contact the appropriate emergency service, protect life, and comply with lawful instructions. The application is a coordination and documentation tool that supports, rather than replaces, professional security practice.

Privacy and security depend on every participant. Users should lock devices, install operating-system updates, avoid untrusted applications, use secure networks when possible, and report a lost device promptly. Administrators should remove access when a guard leaves an assignment, review report recipients, monitor account status, and avoid granting broader permissions than necessary.

The platform will continue to evolve through feedback from guards and administrators. Future improvements may include expanded analytics, richer support workflows, additional notification channels, stronger device security, improved offline operation, and deeper integrations with approved business systems. New capabilities should be introduced carefully so that speed and convenience do not weaken privacy, accuracy, or operational control.

By using Watch Team, each user contributes to a shared security record. The value of the system comes from timely participation, responsible communication, accurate reporting, and appropriate administrative oversight. The goal is a safer, more accountable, and better coordinated working environment for guards, customers, supervisors, and the communities they serve.''',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.65,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SecurityColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SecurityColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(Icons.logout_rounded,
            color: SecurityColors.red, size: 46),
        title: const Text(
          'Log out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'You will need to sign in again to access Watch Team.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SecurityColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final profile = SessionData.userProfile ?? <String, dynamic>{};
    final name = (profile['fullname'] ?? 'Security Guard').toString();
    final email = (profile['email'] ?? profile['username'] ?? '').toString();
    final phone = (profile['phone'] ?? '').toString();

    final items = <_DrawerEntry>[
      _DrawerEntry(Icons.home_rounded, 'Home', widget.onHome),
      _DrawerEntry(
          Icons.apartment_rounded, 'Select Company', widget.onSelectCompany),
      _DrawerEntry(Icons.tune_rounded, 'Settings',
          () => push(const SettingsScreen())),
      _DrawerEntry(Icons.support_agent_rounded, 'Chat Support',
          () => push(const ChatSupportScreen())),
      _DrawerEntry(Icons.forward_to_inbox_rounded, 'Email Support',
          () => push(const EmailSupportScreen())),
      _DrawerEntry(Icons.help_center_rounded, 'Support Center',
          () => push(const SupportCenterScreen())),
      _DrawerEntry(Icons.star_rate_rounded, 'Feedback', feedback),
      _DrawerEntry(Icons.share_rounded, 'Share App', shareApp),
      _DrawerEntry(Icons.info_outline_rounded, 'About Watch Team', showAbout),
      _DrawerEntry(Icons.system_update_alt_rounded, 'App Version', showVersion),
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * .88,
      backgroundColor: SecurityColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: 220,
              child: Icon(
                Icons.shield_outlined,
                size: 280,
                color: SecurityColors.cyan.withOpacity(.025),
              ),
            ),
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E2941), Color(0xFF07111C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF164B70)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -12,
                        top: -18,
                        child: Icon(
                          Icons.security_rounded,
                          size: 105,
                          color: Colors.white.withOpacity(.035),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: SecurityColors.primary.withOpacity(.15),
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: SecurityColors.primary.withOpacity(.6),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_pin_rounded,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      color: SecurityColors.cyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(21, 15, 21, 6),
                  child: Row(
                    children: [
                      const Text(
                        'SECURE NAVIGATION',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: SecurityColors.green.withOpacity(.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'ONLINE',
                          style: TextStyle(
                            color: SecurityColors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      if (index == 3 || index == 8) {
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Divider(color: SecurityColors.border),
                            ),
                            animatedItem(index, _tile(items[index])),
                          ],
                        );
                      }
                      return animatedItem(index, _tile(items[index]));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  child: animatedItem(
                    items.length + 1,
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SecurityColors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(_DrawerEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: SecurityColors.primary.withOpacity(.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(entry.icon, color: const Color(0xFF83B7D5), size: 21),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white24,
          size: 20,
        ),
        onTap: entry.onTap,
      ),
    );
  }
}

class _DrawerEntry {
  final IconData icon;
  final String title;
  final FutureOrVoidCallback onTap;

  const _DrawerEntry(this.icon, this.title, this.onTap);
}

typedef FutureOrVoidCallback = dynamic Function();
