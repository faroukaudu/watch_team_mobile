import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../global.dart' as g;
import '../session_data.dart';

class PostSiteContactScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;

  const PostSiteContactScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<PostSiteContactScreen> createState() => _PostSiteContactScreenState();
}

class _PostSiteContactScreenState extends State<PostSiteContactScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? client;
  Map<String, dynamic>? postSite;

  @override
  void initState() {
    super.initState();
    fetchContact();
  }

  Future<void> fetchContact() async {
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
          client = data['client'] == null
              ? null
              : Map<String, dynamic>.from(data['client']);

          postSite = data['postSite'] == null
              ? null
              : Map<String, dynamic>.from(data['postSite']);

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Unable to load contact.';
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
    final clientName =
        client?['fullname'] ?? postSite?['clientName'] ?? 'No client assigned';

    final email = client?['email']?.toString() ?? '';
    final phone = client?['phone']?.toString() ?? '';
    final address = postSite?['address']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Contact'),
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
          : Padding(
        padding: const EdgeInsets.all(14),
        child: Card(
          color: const Color(0xFF1E1F21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(
                    Icons.contact_phone,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.phone,
                    color: Colors.greenAccent,
                    size: 23,
                  ),
                  onPressed:
                  phone.isEmpty ? null : () => dialPhone(phone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}