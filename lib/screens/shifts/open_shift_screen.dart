import 'package:flutter/material.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

import 'shift_detail_screen.dart';

class OpenShiftScreen extends StatefulWidget {
  final String? postSiteId;
  final String? postSiteName;

  const OpenShiftScreen({
    super.key,
    this.postSiteId,
    this.postSiteName,
  });

  @override
  State<OpenShiftScreen> createState() => _OpenShiftScreenState();
}

class _OpenShiftScreenState extends State<OpenShiftScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  bool loading = true;
  List<Map<String, dynamic>> shifts = [];

  @override
  void initState() {
    super.initState();
    loadShifts();
  }

  Future<void> loadShifts() async {
    setState(() => loading = true);

    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

      final data = await api.listOpenShifts(
        companyId: companyId,
        guardId: guardId,
        postSiteId: widget.postSiteId,
      );

      setState(() {
        shifts = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load shifts: $e")),
      );
    }
  }

  bool selectedByMe(Map<String, dynamic> shift) {
    final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
    final selected = shift['selectedGuards'];

    if (selected is List) {
      return selected.any((g) => g is Map && g['guardId']?.toString() == guardId);
    }

    return false;
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
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        title: Text(
          "Open Shift",
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
                  widget.postSiteName ?? "Today's Open Shifts",
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Select your assigned shift, then check in to the post site.",
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : shifts.isEmpty
                ? Center(
              child: Text(
                "No open shift available today",
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadShifts,
              color: primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  final shift = shifts[index];
                  final selected = selectedByMe(shift);

                  final selectedGuards = shift['selectedGuards'] is List
                      ? shift['selectedGuards'] as List
                      : [];

                  final myGuardId = (SessionData.userProfile?['_id'] ?? '').toString();

                  String selectedGuardLabel = "";

                  if (selectedGuards.isNotEmpty) {
                    final firstSelected = selectedGuards.first;

                    if (firstSelected is Map) {
                      final selectedGuardId = firstSelected['guardId']?.toString() ?? "";
                      final selectedGuardName = firstSelected['guardName']?.toString() ?? "Guard";

                      selectedGuardLabel = selectedGuardId == myGuardId ? "You" : selectedGuardName;
                    }
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShiftDetailScreen(
                            shift: shift,
                          ),
                        ),
                      );

                      if (result == true) loadShifts();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
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
                            height: 118,
                            decoration: BoxDecoration(
                              color: selected
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
                                          shift['shiftTitle']
                                              ?.toString() ??
                                              "Shift",
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
                                          color: selected
                                              ? Colors.green
                                              .withOpacity(.15)
                                              : primary
                                              .withOpacity(.15),
                                          borderRadius:
                                          BorderRadius.circular(
                                              20),
                                        ),
                                        child: Text(
                                          selected
                                              ? "Selected"
                                              : "Open",
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.greenAccent
                                                : primary,
                                            fontWeight:
                                            FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    shift['postSiteName']
                                        ?.toString() ??
                                        "No Post Site",
                                    style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 16, color: muted),
                                      const SizedBox(width: 5),

                                      Text(
                                        "${shift['startTime'] ?? ''} - ${shift['endTime'] ?? ''}",
                                        style: TextStyle(
                                          color: muted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),

                                      const Spacer(), // 👈 pushes badge to far right

                                      if (selectedGuardLabel.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withOpacity(.18),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.blueGrey.withOpacity(.35)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.local_police,
                                                size: 14,
                                                color: Colors.orangeAccent,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                selectedGuardLabel,
                                                style: const TextStyle(
                                                  color: Colors.orangeAccent,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
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