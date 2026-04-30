import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/api_client.dart';

class EditNoteScreen extends StatefulWidget {
  const EditNoteScreen({super.key});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);

  final TextEditingController titleController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool initialized = false;
  bool saving = false;

  late Map<String, dynamic> noteData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (initialized) return;

    noteData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    titleController.text = (noteData['title'] ?? '').toString();
    noteController.text = (noteData['note'] ?? '').toString();

    initialized = true;
  }

  Future<void> saveNote() async {
    final noteID = (noteData['_id'] ?? '').toString();
    final title = titleController.text.trim();
    final note = noteController.text.trim();

    if (noteID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid note ID.")),
      );
      return;
    }

    if (title.isEmpty || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and note are required.")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final res = await api.updateNote(
        noteID: noteID,
        title: title,
        note: note,
      );

      if (res['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Note updated successfully.")),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(res['message'] ?? "Unable to update note.");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
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
    final postSiteName = (noteData['postSiteName'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        title: const Text(
          "Edit Note",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (postSiteName.isNotEmpty) ...[
              const Text(
                "Post Site",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                postSiteName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              "Title",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
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
              minLines: 8,
              maxLines: 14,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
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
                onPressed: saving ? null : saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3DFF),
                  foregroundColor: Colors.white,
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}