import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);

  List<DateTime> weekDates = [];
  Map<String, bool> availability = {};
  List<Map<String, dynamic>> timeOffRequests = [];

  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    buildCurrentWeek();
    loadTimeOff();
  }

  String toDateOnly(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  DateTime? safeDateOnlyParse(dynamic raw) {
    if (raw == null) return null;

    final text = raw.toString().trim();

    // Case 1: 2026-05-01 or 2026-05-01T00:00:00.000Z
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)) {
      final dateOnly = text.split("T").first;
      final parts = dateOnly.split("-");

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    // Case 2: Friday May 01 2026 00:00:00 GMT+0100...
    final cleaned = text.split(" GMT").first;

    try {
      return DateFormat("EEEE MMM dd yyyy HH:mm:ss").parse(cleaned);
    } catch (_) {}

    try {
      return DateFormat("EEE MMM dd yyyy HH:mm:ss").parse(cleaned);
    } catch (_) {}

    return null;
  }

  String formatNiceRange(dynamic fromRaw, dynamic toRaw) {
    final from = safeDateOnlyParse(fromRaw);
    final to = safeDateOnlyParse(toRaw);

    if (from == null || to == null) {
      return "N/A";
    }

    final fromStr = DateFormat('EEEE MMM dd').format(from);
    final toStr = DateFormat('EEE MMM dd').format(to);

    return "$fromStr - $toStr";
  }

  void buildCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    weekDates = List.generate(7, (i) {
      return DateTime(monday.year, monday.month, monday.day + i);
    });

    for (final date in weekDates) {
      availability[toDateOnly(date)] = true;
    }
  }

  Future<void> loadTimeOff() async {
    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

      final data = await api.getMyTimeOffRequests(
        companyId: companyId,
        guardId: guardId,
      );

      setState(() {
        timeOffRequests = data;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  bool hasPendingRequest() {
    return timeOffRequests.any((r) => r['status'] == "Pending");
  }

  Future<void> openTimeOffModal() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    if (picked == null) return;

    await submitTimeOff(picked);
  }

  Future<void> submitTimeOff(DateTimeRange range) async {
    setState(() => submitting = true);

    try {
      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
      final guardName =
      (SessionData.userProfile?['fullname'] ?? 'Guard').toString();
      final guardEmail =
      (SessionData.userProfile?['email'] ?? '').toString();

      await api.submitTimeOffRequest(
        payload: {
          'companyId': companyId,
          'guardId': guardId,
          'guardName': guardName,
          'guardEmail': guardEmail,
          'fromDate': toDateOnly(range.start),
          'toDate': toDateOnly(range.end),
        },
      );

      await loadTimeOff();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time off request submitted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit time off: $e")),
      );
    } finally {
      setState(() => submitting = false);
    }
  }

  Color statusColor(String status) {
    if (status == "Accepted") return Colors.greenAccent;
    if (status == "Rejected") return Colors.redAccent;
    return Colors.orangeAccent;
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

    final pending = hasPendingRequest();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        title: Text(
          "Availability",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pending || submitting ? null : openTimeOffModal,
        backgroundColor: pending ? Colors.grey.shade700 : Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: Icon(pending ? Icons.hourglass_bottom : Icons.event_busy),
        label: Text(
          pending
              ? "Time Off Pending"
              : submitting
              ? "Submitting..."
              : "Time Off",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : ListView(
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
                  bottom: -18,
                  child: Icon(
                    Icons.timer_rounded,
                    size: 135,
                    color: Colors.white.withOpacity(.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.event_available,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(.25),
                            ),
                          ),
                          child: Text(
                            "${DateFormat('MMM dd').format(weekDates.first)} - ${DateFormat('MMM dd').format(weekDates.last)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Weekly Availability",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "You are available by default. Toggle off any day you are unavailable.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.82),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...weekDates.map((date) {
            final key = toDateOnly(date);
            final label = DateFormat('dd-MMM-EEEE').format(date);
            final isAvailable = availability[key] ?? true;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isAvailable
                      ? Colors.greenAccent.withOpacity(.35)
                      : Colors.redAccent.withOpacity(.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.12),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isAvailable
                        ? Colors.green.withOpacity(.18)
                        : Colors.red.withOpacity(.18),
                    child: Icon(
                      isAvailable ? Icons.check_circle : Icons.cancel,
                      color: isAvailable
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Switch(
                    value: isAvailable,
                    activeColor: Colors.greenAccent,
                    activeTrackColor: Colors.green.withOpacity(.35),
                    inactiveThumbColor: Colors.redAccent,
                    inactiveTrackColor: Colors.red.withOpacity(.25),
                    onChanged: (value) {
                      setState(() {
                        availability[key] = value;
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          if (timeOffRequests.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              "Time Off Requests",
              style: TextStyle(
                color: text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ...timeOffRequests.take(5).map((r) {
              final status = r['status']?.toString() ?? "Pending";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor(status).withOpacity(.25),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                      statusColor(status).withOpacity(.15),
                      child: Icon(
                        status == "Accepted"
                            ? Icons.check
                            : status == "Rejected"
                            ? Icons.close
                            : Icons.hourglass_bottom,
                        color: statusColor(status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formatNiceRange(r['fromDate'], r['toDate']),
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor(status),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}