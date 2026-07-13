
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_team/widgets/security_ui.dart';

class EmailSupportScreen extends StatefulWidget {
  const EmailSupportScreen({super.key});

  @override
  State<EmailSupportScreen> createState() => _EmailSupportScreenState();
}

class _EmailSupportScreenState extends State<EmailSupportScreen> {
  static const supportEmail = 'fagzy99@gmail.com';
  final subjectController = TextEditingController(text: 'Watch Team Support');
  final messageController = TextEditingController();

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your support message')),
      );
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': subjectController.text.trim(),
        'body': messageController.text.trim(),
      },
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email application was found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecurityPage(
      title: 'Email Support',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SecuritySectionCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0x2219B5FE),
                    child: Icon(Icons.support_agent_rounded,
                        color: SecurityColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dedicated Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supportEmail,
                          style: const TextStyle(color: SecurityColors.cyan),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SecuritySectionCard(
              child: Column(
                children: [
                  TextField(
                    controller: subjectController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.subject_rounded,
                          color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: messageController,
                    minLines: 7,
                    maxLines: 12,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Describe how we can assist you...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: SecurityColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SecurityColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Open Email App'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
