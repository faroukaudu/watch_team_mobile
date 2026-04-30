import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/services/api_client.dart';
import 'dispatch_detail_screen.dart';

class DispatchListScreen extends StatefulWidget {
  const DispatchListScreen({super.key});

  @override
  State<DispatchListScreen> createState() => _DispatchListScreenState();
}

class _DispatchListScreenState extends State<DispatchListScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  bool loading = true;
  DateTime? selectedDate;
  List<Map<String, dynamic>> dispatchList = [];

  @override
  void initState() {
    super.initState();
    loadDispatch();
  }

  Future<void> loadDispatch() async {
    setState(() => loading = true);

    try {
      DateTime? start;
      DateTime? end;

      if (selectedDate != null) {
        start = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        end = start.add(const Duration(days: 1));
      }

      final data = await api.listGuardDispatch(
        startDate: start,
        endDate: end,
      );

      setState(() {
        dispatchList = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load dispatch: $e")),
      );
    }
  }

  Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case "high":
        return Colors.redAccent;
      case "medium":
        return Colors.orangeAccent;
      default:
        return Colors.lightBlueAccent;
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
      loadDispatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final mutedColor = theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        title: Text(
          "Dispatch",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month, color: textColor),
            onPressed: pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: textColor.withOpacity(.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assigned Dispatch",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedDate == null
                      ? "Showing all dispatch assigned to you"
                      : "Filtered: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}",
                  style: TextStyle(color: mutedColor),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pickDate,
                        icon: const Icon(Icons.filter_alt),
                        label: const Text("Filter by Date"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (selectedDate != null)
                      ElevatedButton(
                        onPressed: () {
                          setState(() => selectedDate = null);
                          loadDispatch();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardColor,
                          foregroundColor: textColor,
                          elevation: 0,
                          side: BorderSide(color: textColor.withOpacity(.12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.close),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
                : dispatchList.isEmpty
                ? Center(
              child: Text(
                "No dispatch found",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadDispatch,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dispatchList.length,
                itemBuilder: (context, index) {
                  final item = dispatchList[index];
                  final status = (item['status'] ?? 'Pending').toString();
                  final accepted = status == "Accepted";
                  final priority = (item['priority'] ?? 'Low').toString();
                  final badgeColor = accepted ? Colors.greenAccent : priorityColor(priority);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DispatchDetailScreen(dispatch: item),
                        ),
                      );

                      if (result == true) {
                        loadDispatch();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accepted
                              ? Colors.greenAccent.withOpacity(.45)
                              : textColor.withOpacity(.07),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.16),
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
                              color: badgeColor,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['ticketId']?.toString() ?? 'DSP-N/A',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withOpacity(.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: badgeColor.withOpacity(.35),
                                          ),
                                        ),
                                        child: Text(
                                          priority,
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item['postSiteName']?.toString() ?? 'No Post Site',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    item['incidentType']?.toString() ?? 'No Incident Type',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        accepted ? Icons.check_circle : Icons.schedule,
                                        size: 16,
                                        color: accepted ? Colors.greenAccent : Colors.orangeAccent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        accepted ? "Approved" : "Pending Approval",
                                        style: TextStyle(
                                          color: accepted ? Colors.greenAccent : Colors.orangeAccent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
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