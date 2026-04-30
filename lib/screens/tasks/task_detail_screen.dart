import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final DateTime selectedDate;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.selectedDate,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  Set<int> checkedSubTasks = {};
  bool completing = false;

  List<dynamic> get subTasks {
    final raw = widget.task['subTasks'];
    return raw is List ? raw : [];
  }

  bool get allChecked {
    if (subTasks.isEmpty) return true;
    return checkedSubTasks.length == subTasks.length;
  }

  String subTaskTitle(dynamic item) {
    if (item is Map && item['title'] != null) return item['title'].toString();
    return item.toString();
  }

  String value(String key) {
    final v = widget.task[key];
    if (v == null || v.toString().trim().isEmpty) return "N/A";
    return v.toString();
  }

  Future<void> completeTask() async {
    if (!allChecked || completing) return;

    setState(() => completing = true);

    try {
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
      final dateOnly = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      await api.completePostSiteTask(
        taskId: widget.task['_id'].toString(),
        guardId: guardId,
        completedDate: dateOnly,
        completedSubTasks: checkedSubTasks.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task completed successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to complete task: $e")),
      );
    }
  }

  Widget infoTile({
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted =
        theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withOpacity(.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.primaryColor.withOpacity(.15),
            child: Icon(icon, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    final type = widget.task['taskType']?.toString() ?? "Task";
    final isRecurring = type == "Recurring";

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        title: Text(
          "Task Details",
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
              onPressed: allChecked && !completing ? completeTask : null,
              icon: completing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.check_circle),
              label: Text(
                completing ? "Completing..." : "Complete Task",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: text.withOpacity(.15),
                disabledForegroundColor: text.withOpacity(.35),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  primary.withOpacity(.75),
                  Colors.deepOrange.withOpacity(.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(.32),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  bottom: -20,
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 135,
                    color: Colors.white.withOpacity(.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.task_alt, color: Colors.white, size: 44),
                    const SizedBox(height: 14),
                    Text(
                      value("taskName"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task['taskDescription']?.toString() ??
                          "No description",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat('EEE, MMM dd')
                                .format(widget.selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          infoTile(
            icon: Icons.timer,
            title: "Max Duration",
            content: value("maxDuration"),
          ),
          infoTile(
            icon: Icons.location_on,
            title: "Post Site",
            content: value("postSiteName"),
          ),
          infoTile(
            icon: isRecurring ? Icons.repeat : Icons.event,
            title: "Task Type",
            content: type,
          ),
          const SizedBox(height: 8),
          Text(
            "Sub Tasks",
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          if (subTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: text.withOpacity(.08)),
              ),
              child: Text(
                "No sub task. Tap complete task when done.",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            )
          else
            ...List.generate(subTasks.length, (index) {
              final checked = checkedSubTasks.contains(index);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: checked
                        ? Colors.greenAccent.withOpacity(.45)
                        : text.withOpacity(.08),
                  ),
                ),
                child: CheckboxListTile(
                  value: checked,
                  activeColor: Colors.green,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: Text(
                    subTaskTitle(subTasks[index]),
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      decoration:
                      checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    checked ? "Done" : "Pending",
                    style: TextStyle(
                      color: checked ? Colors.greenAccent : muted,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        checkedSubTasks.add(index);
                      } else {
                        checkedSubTasks.remove(index);
                      }
                    });
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}