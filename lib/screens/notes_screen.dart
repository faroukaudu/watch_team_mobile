import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/session_data.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);

  bool loading = true;
  List<Map<String, dynamic>> notes = [];

  DateTime? startDate;
  DateTime? endDate;

  String get companyID =>
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();

  String get guardID =>
      (SessionData.userProfile?['_id'] ??
          SessionData.userProfile?['id'] ??
          '')
          .toString();

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    setState(() => loading = true);

    try {
      final result = await api.listGuardNotes(
        companyID: companyID,
        guardID: guardID,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      setState(() {
        notes = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load notes: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => startDate = picked);
      await loadNotes();
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => endDate = picked);
      await loadNotes();
    }
  }

  void clearFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });

    loadNotes();
  }

  String formatDate(dynamic value) {
    if (value == null) return "";

    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();

    final local = dt.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}";
  }

  String shortDate(DateTime? date) {
    if (date == null) return "Select";

    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(date.day)}/${two(date.month)}/${date.year}";
  }

  void viewNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: Text(
            (note['title'] ?? 'Note').toString(),
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Post Site: ${(note['postSiteName'] ?? '').toString()}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  "Date: ${formatDate(note['createdAt'])}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const Divider(color: Colors.white24),
                Text(
                  (note['note'] ?? '').toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> editNote(Map<String, dynamic> note) async {
    final updated = await Navigator.pushNamed(
      context,
      '/edit_note',
      arguments: note,
    );

    if (updated == true) {
      loadNotes();
    }
  }

  Future<void> addNewNote() async {
    final created = await Navigator.pushNamed(context, '/add_note');

    if (created == true) {
      loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        title: const Text(
          "Notes",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickStartDate,
                        icon: const Icon(Icons.date_range),
                        label: Text("From: ${shortDate(startDate)}"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickEndDate,
                        icon: const Icon(Icons.date_range),
                        label: Text("To: ${shortDate(endDate)}"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: clearFilter,
                    child: const Text("Clear Date Filter"),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                ? const Center(
              child: Text(
                "No notes found.",
                style: TextStyle(color: Colors.white70),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadNotes,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];

                  return Card(
                    color: const Color(0xFF171717),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        (note['title'] ?? 'Untitled Note').toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            (note['postSiteName'] ?? 'Post Site').toString(),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(note['createdAt']),
                            style: const TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        color: const Color(0xFF222222),
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'view') {
                            viewNote(note);
                          }

                          if (value == 'edit') {
                            editNote(note);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'view',
                            child: Text("View"),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text("Edit"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: addNewNote,
            icon: const Icon(Icons.add),
            label: const Text("Add New Note"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3DFF),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}