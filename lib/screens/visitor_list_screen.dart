import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

import 'add_visitor_screen.dart';
import 'visitor_detail_screen.dart';

class VisitorListScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;

  const VisitorListScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  bool loading = true;
  DateTime? selectedDate;
  List<Map<String, dynamic>> visitors = [];

  @override
  void initState() {
    super.initState();
    loadVisitors();
  }

  Future<void> loadVisitors() async {
    setState(() => loading = true);

    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();

      DateTime? start;
      DateTime? end;

      if (selectedDate != null) {
        start = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        end = start.add(const Duration(days: 1));
      }

      final data = await api.listVisitors(
        companyId: companyId,
        postSiteId: widget.postSiteId,
        startDate: start,
        endDate: end,
      );

      setState(() {
        visitors = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load visitors: $e")),
      );
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      loadVisitors();
    }
  }

  String formatDate(dynamic raw) {
    if (raw == null) return "N/A";
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(raw.toString()));
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
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        centerTitle: true,
        title: Text(
          "Visitors",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: pickDate,
            icon: Icon(Icons.calendar_month, color: text),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddVisitorScreen(
                      postSiteId: widget.postSiteId,
                      postSiteName: widget.postSiteName,
                    ),
                  ),
                );

                if (result == true) loadVisitors();
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text("Add Visitor"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
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
                ),
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
                  selectedDate == null
                      ? "Showing all visitors added by guards"
                      : "Filtered: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}",
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pickDate,
                        icon: const Icon(Icons.filter_alt),
                        label: const Text("Filter by Date"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => selectedDate = null);
                          loadVisitors();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: card,
                          foregroundColor: text,
                          side: BorderSide(color: text.withOpacity(.12)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : visitors.isEmpty
                ? Center(
              child: Text(
                "No visitors found",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadVisitors,
              color: primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visitors.length,
                itemBuilder: (context, index) {
                  final v = visitors[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisitorDetailScreen(visitor: v),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: text.withOpacity(.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.14),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: primary.withOpacity(.15),
                            backgroundImage: v['visitorFace'] != null &&
                                v['visitorFace']['secureUrl'] != null
                                ? NetworkImage(v['visitorFace']['secureUrl'])
                                : null,
                            child: v['visitorFace'] == null ||
                                v['visitorFace']['secureUrl'] == null
                                ? Icon(Icons.person, color: primary)
                                : null,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v['visitorName']?.toString() ?? "Unnamed Visitor",
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  v['purposeOfVisit']?.toString() ?? "No purpose entered",
                                  style: TextStyle(color: muted, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatDate(v['visitDateTime']),
                                  style: TextStyle(color: muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: muted),
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