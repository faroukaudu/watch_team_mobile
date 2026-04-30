import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/screens/shifts/shift_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  bool loading = true;
  List<Map<String, dynamic>> shifts = [];

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    setState(() => loading = true);

    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

      final data = await api.getMySchedule(
        companyId: companyId,
        guardId: guardId,
      );

      setState(() {
        shifts = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load schedule: $e")),
      );
    }
  }

  String todayName() {
    return DateFormat('EEEE').format(DateTime.now());
  }

  bool runsToday(Map<String, dynamic> shift) {
    final repeatDays = shift['repeatDays'];
    if (repeatDays is List) {
      return repeatDays.map((e) => e.toString()).contains(todayName());
    }
    return false;
  }

  bool selectedByMe(Map<String, dynamic> shift) {
    final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
    final selected = shift['selectedGuards'];

    if (selected is List) {
      return selected.any((g) => g is Map && g['guardId']?.toString() == guardId);
    }

    return false;
  }

  Map<String, dynamic>? nextShift() {
    final today = todayName();

    final todayShifts = shifts.where((s) {
      final days = s['repeatDays'];
      if (days is! List) return false;
      return days.map((e) => e.toString()).contains(today);
    }).toList();

    if (todayShifts.isEmpty) return null;

    todayShifts.sort((a, b) {
      return (a['startTime'] ?? '').toString().compareTo(
        (b['startTime'] ?? '').toString(),
      );
    });

    return todayShifts.first;
  }

  String repeatText(Map<String, dynamic> shift) {
    final days = shift['repeatDays'];
    if (days is List && days.isNotEmpty) {
      return days.join(", ");
    }
    return "No repeat day";
  }

  String selectedStatus(Map<String, dynamic> shift) {
    if (selectedByMe(shift)) return "Selected";
    if (runsToday(shift)) return "Today";
    return "Scheduled";
  }

  Color statusColor(Map<String, dynamic> shift) {
    if (selectedByMe(shift)) return Colors.greenAccent;
    if (runsToday(shift)) return Colors.orangeAccent;
    return Colors.lightBlueAccent;
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

    final upcoming = nextShift();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        centerTitle: true,
        title: Text(
          "Schedule",
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
        onRefresh: loadSchedule,
        color: primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
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
                    right: -14,
                    bottom: -18,
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 135,
                      color: Colors.white.withOpacity(.12),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.event_note,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "My Schedule",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        upcoming == null
                            ? "No scheduled shift for today."
                            : "Next shift: ${upcoming['shiftTitle'] ?? 'Shift'} at ${upcoming['startTime'] ?? ''}",
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

            const SizedBox(height: 18),

            if (shifts.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: text.withOpacity(.08)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, color: muted, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      "No Schedule Found",
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Assigned or selected shifts will appear here.",
                      style: TextStyle(color: muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...shifts.map((shift) {
                final color = statusColor(shift);

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftDetailScreen(shift: shift),
                      ),
                    );

                    if (result == true) loadSchedule();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withOpacity(.35)),
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
                          height: 125,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        shift['shiftTitle']?.toString() ??
                                            "Shift",
                                        style: TextStyle(
                                          color: text,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(.15),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        selectedStatus(shift),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  shift['postSiteName']?.toString() ??
                                      "Post Site",
                                  style: TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.schedule,
                                        size: 16, color: muted),
                                    const SizedBox(width: 5),
                                    Text(
                                      "${shift['startTime'] ?? ''} - ${shift['endTime'] ?? ''}",
                                      style: TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  repeatText(shift),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}