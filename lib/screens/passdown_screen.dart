import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../global.dart' as g;
import '../session_data.dart';

class PassdownScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;

  const PassdownScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<PassdownScreen> createState() => _PassdownScreenState();
}

class _PassdownScreenState extends State<PassdownScreen> {
  bool isLoading = true;
  List passdowns = [];
  String? errorMessage;

  final titleController = TextEditingController();
  final messageController = TextEditingController();

  String priority = "Normal";
  String visibility = "All Guards";

  @override
  void initState() {
    super.initState();
    fetchPassdowns();
  }

  Future<void> fetchPassdowns() async {
    try {
      final companyId =
          SessionData.userProfile?['assignedCompanyID']?.toString() ?? '';

      final url = Uri.parse(
        '${g.baseUrl}/api/passdowns?companyId=$companyId&postSiteId=${widget.postSiteId}',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          passdowns = data['passdowns'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Unable to load passdowns.';
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

  Future<void> createPassdown() async {
    final message = messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passdown message is required.')),
      );
      return;
    }

    try {
      final companyId =
          SessionData.userProfile?['assignedCompanyID']?.toString() ?? '';

      final guardId = SessionData.userProfile?['_id']?.toString() ?? '';

      final guardName =
          SessionData.userProfile?['fullname']?.toString() ??
              SessionData.userProfile?['username']?.toString() ??
              '';

      final response = await http.post(
        Uri.parse('${g.baseUrl}/api/passdowns/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'companyId': companyId,
          'postSiteId': widget.postSiteId,
          'postSiteName': widget.postSiteName,
          'guardId': guardId,
          'guardName': guardName,
          'title': titleController.text.trim().isEmpty
              ? 'Passdown Note'
              : titleController.text.trim(),
          'message': message,
          'priority': priority,
          'visibility': visibility,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        titleController.clear();
        messageController.clear();

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passdown created successfully.')),
        );

        fetchPassdowns();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Unable to create passdown.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to connect to server.')),
      );
    }
  }

  Future<void> markAsRead(String passdownId) async {
    try {
      final guardId = SessionData.userProfile?['_id']?.toString() ?? '';
      final guardName =
          SessionData.userProfile?['fullname']?.toString() ??
              SessionData.userProfile?['username']?.toString() ??
              '';

      await http.post(
        Uri.parse('${g.baseUrl}/api/passdowns/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'passdownId': passdownId,
          'guardId': guardId,
          'guardName': guardName,
        }),
      );

      fetchPassdowns();
    } catch (_) {}
  }

  void openCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1F21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create Passdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Message / Handover Note',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      dropdownColor: const Color(0xFF1E1F21),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                      ],
                      onChanged: (value) {
                        setModalState(() => priority = value ?? 'Normal');
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: visibility,
                      dropdownColor: const Color(0xFF1E1F21),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Visibility',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Guards',
                          child: Text('All Guards'),
                        ),
                        DropdownMenuItem(
                          value: 'Next Shift',
                          child: Text('Next Shift'),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() => visibility = value ?? 'All Guards');
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: createPassdown,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          'Submit Passdown',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void viewPassdown(Map<String, dynamic> item) {
    markAsRead(item['_id'].toString());

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1F21),
          title: Text(
            item['title'] ?? 'Passdown',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            item['message'] ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Passdown - ${widget.postSiteName}'),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: openCreateModal,
        child: const Icon(Icons.add, color: Colors.white),
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
          : passdowns.isEmpty
          ? const Center(
        child: Text(
          'No passdown logs yet.',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: passdowns.length,
        itemBuilder: (context, index) {
          final item = passdowns[index];
          final isUrgent = item['priority'] == 'Urgent';

          return Card(
            color: const Color(0xFF1E1F21),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () =>
                  viewPassdown(Map<String, dynamic>.from(item)),
              leading: CircleAvatar(
                backgroundColor:
                isUrgent ? Colors.red : Colors.blueGrey,
                child: Icon(
                  isUrgent
                      ? Icons.priority_high
                      : Icons.notes,
                  color: Colors.white,
                ),
              ),
              title: Text(
                item['title'] ?? 'Passdown Note',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${item['guardName'] ?? 'Guard'}\n${item['message'] ?? ''}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.white54,
              ),
            ),
          );
        },
      ),
    );
  }
}