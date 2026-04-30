import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

import 'checklist_detail_screen.dart';

class ChecklistListScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;


  const ChecklistListScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,

  });

  @override
  State<ChecklistListScreen> createState() => _ChecklistListScreenState();
}

class _ChecklistListScreenState extends State<ChecklistListScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);
  DateTime? selectedDate;

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      loadChecklists();
    }
  }

  bool loading = true;
  List<Map<String, dynamic>> checklists = [];

  @override
  void initState() {
    super.initState();
    loadChecklists();
  }

  Future<void> loadChecklists() async {
    setState(() => loading = true);

    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

      final data = await api.listGuardChecklists(
        companyId: companyId,
        postSiteId: widget.postSiteId,
        guardId: guardId,
        startDate: selectedDate == null
            ? null
            : DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day),
        endDate: selectedDate == null
            ? null
            : DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day)
            .add(const Duration(days: 1)),
      );

      setState(() {
        checklists = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load checklists: $e")),
      );
    }
  }

  Map<String, dynamic> guardProgress(Map<String, dynamic> checklist) {
    final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
    final progressList = checklist['progress'];

    if (progressList is List) {
      for (final p in progressList) {
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

  int totalItems(Map<String, dynamic> checklist) {
    final items = checklist['items'];
    return items is List ? items.length : 0;
  }

  int checkedCount(Map<String, dynamic> checklist) {
    final progress = guardProgress(checklist);
    final checkedItems = progress['checkedItems'];
    return checkedItems is List ? checkedItems.length : 0;
  }

  bool isCompleted(Map<String, dynamic> checklist) {
    final progress = guardProgress(checklist);
    return progress['completed'] == true;
  }

  String formatDate(dynamic raw) {
    if (raw == null) return "N/A";
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
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
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month, color: text),
            onPressed: pickDate,
          ),
        ],
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        title: Text(
          "Checklists",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                  widget.postSiteName,
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Assigned checklist tasks for this post site",
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : checklists.isEmpty
                ? Center(
              child: Text(
                "No checklist assigned",
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadChecklists,
              color: primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  final total = totalItems(item);
                  final checked = checkedCount(item);
                  final completed = isCompleted(item);
                  final percentage =
                  total == 0 ? 0.0 : checked / total;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChecklistDetailScreen(checklist: item),
                        ),
                      );

                      if (result == true) {
                        loadChecklists();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: completed
                              ? Colors.greenAccent.withOpacity(.45)
                              : text.withOpacity(.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.14),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 120,
                            decoration: BoxDecoration(
                              color: completed
                                  ? Colors.greenAccent
                                  : primary,
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
                                          item['name']?.toString() ??
                                              "Checklist",
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
                                          color: completed
                                              ? Colors.green
                                              .withOpacity(.15)
                                              : Colors.orange
                                              .withOpacity(.15),
                                          borderRadius:
                                          BorderRadius.circular(
                                              20),
                                        ),
                                        child: Text(
                                          completed
                                              ? "Completed"
                                              : "In Progress",
                                          style: TextStyle(
                                            color: completed
                                                ? Colors.greenAccent
                                                : Colors.orangeAccent,
                                            fontWeight:
                                            FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    item['description']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                        true
                                        ? item['description']
                                        .toString()
                                        : "No description",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 7,
                                      backgroundColor:
                                      text.withOpacity(.08),
                                      color: completed
                                          ? Colors.greenAccent
                                          : primary,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text(
                                        "$checked/$total completed",
                                        style: TextStyle(
                                          color: muted,
                                          fontWeight:
                                          FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        formatDate(item['createdAt']),
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
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