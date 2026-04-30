import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String? postSiteId;
  final String? postSiteName;

  const TaskListScreen({
    super.key,
    this.postSiteId,
    this.postSiteName,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  bool loading = true;
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => loading = true);

    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

      final data = await api.listPostSiteTasks(
        companyId: companyId,
        guardId: guardId,
        postSiteId: widget.postSiteId,
        date: selectedDate,
      );

      setState(() {
        tasks = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load tasks: $e")),
      );
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() => selectedDate = picked);
    loadTasks();
  }

  String taskType(Map<String, dynamic> task) {
    return task['taskType']?.toString() ?? "Task";
  }

  bool hasSubTasks(Map<String, dynamic> task) {
    return task['subTasks'] is List && (task['subTasks'] as List).isNotEmpty;
  }

  String getDuration(Map<String, dynamic> task) {
    return task['maxDuration']?.toString() ?? "N/A";
  }

  Color typeColor(Map<String, dynamic> task) {
    return taskType(task) == "Recurring"
        ? Colors.lightBlueAccent
        : Colors.orangeAccent;
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        centerTitle: true,
        title: Text(
          "Tasks",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month, color: text),
            onPressed: pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  primary.withOpacity(.78),
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
                  bottom: -22,
                  child: Icon(
                    Icons.task_alt_rounded,
                    size: 135,
                    color: Colors.white.withOpacity(.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.white,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.postSiteName ?? "My Tasks",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Showing tasks for ${DateFormat('EEE, MMM dd').format(selectedDate)}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : tasks.isEmpty
                ? Center(
              child: Text(
                "No task found for this date",
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadTasks,
              color: primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final color = typeColor(task);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(
                            task: task,
                            selectedDate: selectedDate,
                          ),
                        ),
                      );

                      if (result == true) loadTasks();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border:
                        Border.all(color: color.withOpacity(.35)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.13),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 118,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task['taskName']
                                              ?.toString() ??
                                              "Task",
                                          style: TextStyle(
                                            color: text,
                                            fontWeight:
                                            FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                          color.withOpacity(.15),
                                          borderRadius:
                                          BorderRadius.circular(
                                              20),
                                        ),
                                        child: Text(
                                          taskType(task),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight:
                                            FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    task['taskDescription']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                        true
                                        ? task['taskDescription']
                                        .toString()
                                        : "No description",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.timer,
                                          size: 16, color: muted),
                                      const SizedBox(width: 5),
                                      Text(
                                        getDuration(task),
                                        style: TextStyle(
                                          color: muted,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Icon(Icons.list_alt,
                                          size: 16, color: muted),
                                      const SizedBox(width: 5),
                                      Text(
                                        hasSubTasks(task)
                                            ? "${(task['subTasks'] as List).length} sub tasks"
                                            : "No sub task",
                                        style: TextStyle(
                                          color: muted,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}