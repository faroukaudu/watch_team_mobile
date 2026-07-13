
import 'package:flutter/material.dart';
import 'package:watch_team/widgets/security_ui.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('How do I select a post site?',
       'Open Select Company from the drawer and choose one of the companies or post sites assigned to your account.'),
      ('Why can I not submit a report?',
       'Confirm that a post site is selected, your internet connection is active, and all required report fields are completed.'),
      ('How does Code Red work?',
       'A Code Red report immediately notifies the recipients configured for the selected post site. Use it only for urgent security events.'),
      ('How do I reset my password?',
       'Tap Forgot Password on the login screen, enter the registered guard email, verify the OTP, and create a new password.'),
      ('Why is location required?',
       'Location supports check-in, patrol accountability, live tracking, and confirmation that security duties are performed at the correct site.'),
    ];

    return SecurityPage(
      title: 'Support Center',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SecuritySectionCard(
            child: Column(
              children: [
                Icon(Icons.health_and_safety_outlined,
                    size: 48, color: SecurityColors.primary),
                SizedBox(height: 10),
                Text(
                  'Watch Team Help Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Quick answers for common guard-app questions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...faqs.map(
            (faq) => Card(
              color: SecurityColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: SecurityColors.border),
              ),
              child: ExpansionTile(
                iconColor: SecurityColors.primary,
                collapsedIconColor: Colors.white54,
                title: Text(
                  faq.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq.$2,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
