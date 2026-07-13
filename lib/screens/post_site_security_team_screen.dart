import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../global.dart' as g;
import '../session_data.dart';

class PostSiteSecurityTeamScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;

  const PostSiteSecurityTeamScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<PostSiteSecurityTeamScreen> createState() =>
      _PostSiteSecurityTeamScreenState();
}

class _PostSiteSecurityTeamScreenState
    extends State<PostSiteSecurityTeamScreen> {
  bool isLoading = true;
  String? errorMessage;
  List guards = [];

  @override
  void initState() {
    super.initState();
    fetchSecurityTeam();
  }

  Future<void> fetchSecurityTeam() async {
    try {
      final companyId =
          SessionData.userProfile?['assignedCompanyID']?.toString() ?? '';

      final url = Uri.parse(
        '${g.baseUrl}/api/mobile/post-site-directory'
            '?companyId=$companyId&postSiteId=${widget.postSiteId}',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          guards = data['guards'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Unable to load security team.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to connect to server.';
        isLoading = false;
      });
    }
  }

  Future<void> dialPhone(String phone) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleanPhone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Security Team'),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.white),
        ),
      )
          : guards.isEmpty
          ? Center(
        child: Text(
          'No guard assigned to ${widget.postSiteName}.',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: guards.length,
        itemBuilder: (context, index) {
          final guard = guards[index];

          final name =
          (guard['fullname'] ?? guard['username'] ?? 'Guard')
              .toString();

          final email = (guard['email'] ?? '').toString();
          final phone = (guard['phone'] ?? '').toString();
          final active = guard['status'] == true;

          return Card(
            color: const Color(0xFF1E1F21),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor:
                active ? Colors.green : Colors.red,
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                [
                  if (email.isNotEmpty) email,
                  if (phone.isNotEmpty) phone,
                  active ? 'Active' : 'Inactive',
                ].join('\n'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.phone,
                  color: Colors.greenAccent,
                  size: 22,
                ),
                onPressed:
                phone.isEmpty ? null : () => dialPhone(phone),
              ),
            ),
          );
        },
      ),
    );
  }
}