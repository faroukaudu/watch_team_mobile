import 'package:flutter/material.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> checklist;

  const ChecklistDetailScreen({
    super.key,
    required this.checklist,
  });

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  late Map<String, dynamic> checklist;
  bool saving = false;
  bool completing = false;

  @override
  void initState() {
    super.initState();
    checklist = Map<String, dynamic>.from(widget.checklist);
  }

  String get guardId => (SessionData.userProfile?['_id'] ?? '').toString();

  List<dynamic> get items {
    final raw = checklist['items'];
    return raw is List ? raw : [];
  }

  Map<String, dynamic> get progress {
    final raw = checklist['progress'];

    if (raw is List) {
      for (final p in raw) {
        if (p is Map && p['guardId']?.toString() == guardId) {
          return Map<String, dynamic>.from(p);
        }
      }
    }

    return {
      'guardId': guardId,
      'checkedItems': [],
      'completed': false,
    };
  }

  Set<int> get checkedItems {
    final raw = progress['checkedItems'];
    if (raw is List) {
      return raw.map((e) => int.tryParse(e.toString()) ?? -1).where((e) => e >= 0).toSet();
    }
    return {};
  }

  bool get allChecked => items.isNotEmpty && checkedItems.length == items.length;

  bool get completed => progress['completed'] == true;

  Future<void> toggleItem(int index, bool checked) async {
    if (saving || completed) return;

    setState(() => saving = true);

    try {
      final res = await api.checkChecklistItem(
        checklistId: checklist['_id'].toString(),
        guardId: guardId,
        itemIndex: index,
        checked: checked,
      );

      if (res['checklist'] is Map) {
        setState(() {
          checklist = Map<String, dynamic>.from(res['checklist']);
          saving = false;
        });
      } else {
        setState(() => saving = false);
      }
    } catch (e) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save check: $e")),
      );
    }
  }

  Future<void> completeChecklist() async {
    if (!allChecked || completing || completed) return;

    setState(() => completing = true);

    try {
      await api.completeChecklist(
        checklistId: checklist['_id'].toString(),
        guardId: guardId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checklist completed successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to complete checklist: $e")),
      );
    }
  }

  String itemText(dynamic item) {
    if (item is Map && item['text'] != null) return item['text'].toString();
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final primary = theme.primaryColor;
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted =
        theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    final count = checkedItems.length;
    final total = items.length;
    final percentage = total == 0 ? 0.0 : count / total;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        title: Text(
          "Checklist Details",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: card,
          border: Border(top: BorderSide(color: text.withOpacity(.08))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed:
              allChecked && !completing && !completed ? completeChecklist : null,
              icon: completing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(completed ? Icons.check_circle : Icons.task_alt),
              label: Text(
                completed
                    ? "Checklist Completed"
                    : completing
                    ? "Completing..."
                    : "Checklist Completed",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: completed ? Colors.green : primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                completed ? Colors.green : text.withOpacity(.15),
                disabledForegroundColor:
                completed ? Colors.white : text.withOpacity(.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: text.withOpacity(.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checklist['name']?.toString() ?? "Checklist",
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  checklist['description']?.toString().trim().isNotEmpty == true
                      ? checklist['description'].toString()
                      : "No description",
                  style: TextStyle(color: muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: text.withOpacity(.08),
                    color: completed ? Colors.greenAccent : primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$count/$total completed",
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(items.length, (index) {
            final isChecked = checkedItems.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isChecked
                      ? Colors.greenAccent.withOpacity(.45)
                      : text.withOpacity(.08),
                ),
              ),
              child: CheckboxListTile(
                value: isChecked,
                onChanged: completed
                    ? null
                    : (value) {
                  toggleItem(index, value == true);
                },
                activeColor: Colors.green,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(
                  itemText(items[index]),
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w700,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Text(
                  isChecked ? "Done" : "Pending",
                  style: TextStyle(
                    color: isChecked ? Colors.greenAccent : muted,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
          if (saving)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  "Saving progress...",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}