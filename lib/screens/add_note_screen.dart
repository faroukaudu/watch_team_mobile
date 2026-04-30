import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/session_data.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);

  final TextEditingController titleController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool submitting = false;

  List<Map<String, dynamic>> postSites = [];
  Map<String, dynamic>? selectedPostSite;


  Map<String, dynamic>? findMatchingPostSite(
      List companyPostSites,
      String assignedPostSiteId,
      ) {
    for (final site in companyPostSites) {
      if (site is Map) {
        final siteId = (site['_id'] ?? '').toString();
        if (siteId == assignedPostSiteId) {
          return Map<String, dynamic>.from(site);
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadPostSites();
  }

  void _loadPostSites() {
    final profile = SessionData.userProfile ?? {};
    final companyInfo = SessionData.companyInfo ?? {};

    final rawAssignedSites = profile['guardPostSite'];
    final companyPostSites = companyInfo['postSite'];

    final List<Map<String, dynamic>> resolvedSites = [];

    if (rawAssignedSites is List && companyPostSites is List) {
      for (final assigned in rawAssignedSites) {
        if (assigned is Map) {
          final assignedPostSiteId =
          (assigned['postSiteID'] ?? assigned['postSiteId'] ?? '').toString();

          if (assignedPostSiteId.isEmpty) continue;

          final matchingSite = findMatchingPostSite(
            companyPostSites,
            assignedPostSiteId,
          );

          if (matchingSite != null) {
            resolvedSites.add({
              'postSiteID': matchingSite['_id'].toString(),
              'siteName': (matchingSite['siteName'] ?? 'Unknown Post Site').toString(),
              'clientName': (matchingSite['clientName'] ?? '').toString(),
            });
          }
        }
      }
    }

    postSites = resolvedSites;

    if (postSites.isNotEmpty) {
      selectedPostSite = postSites.first;
    }

    setState(() {});
  }

  Future<void> _submitNote() async {
    final profile = SessionData.userProfile ?? {};

    if (selectedPostSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a post site.")),
      );
      return;
    }

    final title = titleController.text.trim();
    final note = noteController.text.trim();

    if (title.isEmpty || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and note are required.")),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      final postSiteID =
      (selectedPostSite!['postSiteID'] ?? selectedPostSite!['_id'] ?? '').toString();

      final postSiteName =
      (selectedPostSite!['siteName'] ?? selectedPostSite!['postSiteName'] ?? '').toString();

      final res = await api.createNote(
        companyID: (profile['assignedCompanyID'] ?? '').toString(),
        postSiteID: postSiteID,
        postSiteName: postSiteName,
        guardID: (profile['_id'] ?? profile['id'] ?? '').toString(),
        guardName: (profile['fullname'] ?? profile['username'] ?? '').toString(),
        title: title,
        note: note,
      );

      if (res['success'] == true) {
        titleController.clear();
        noteController.clear();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Note submitted successfully.")),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(res['message'] ?? "Unable to submit note.");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        title: const Text(
          "Add Note",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Post Site",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedPostSite,
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              items: postSites.map((site) {
                final name = (site['siteName'] ?? site['postSiteName'] ?? 'Post Site').toString();

                return DropdownMenuItem<Map<String, dynamic>>(
                  value: site,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPostSite = value;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Title",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter note title",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Note",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: noteController,
              minLines: 7,
              maxLines: 12,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Write note here...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: submitting ? null : _submitNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3DFF),
                  foregroundColor: Colors.white,
                ),
                child: submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Note"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}