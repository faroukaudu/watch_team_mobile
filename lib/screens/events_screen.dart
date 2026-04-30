import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/session_data.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);

  bool loading = true;
  List<Map<String, dynamic>> events = [];

  DateTime? startDate;
  DateTime? endDate;

  String get companyId =>
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();

  String get guardId =>
      (SessionData.userProfile?['_id'] ??
          SessionData.userProfile?['id'] ??
          '')
          .toString();

  List<String> get guardPostSiteIds {
    final raw = SessionData.userProfile?['guardPostSite'];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((site) => (site['postSiteID'] ?? site['postSiteId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() => loading = true);

    try {
      final result = await api.listGuardEvents(
        companyId: companyId,
        guardId: guardId,
        postSiteIds: guardPostSiteIds,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      setState(() {
        events = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load events: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return "N/A";

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

  String resolvePostSiteName(String postSiteId) {
    final companyInfo = SessionData.companyInfo ?? {};
    final postSites = companyInfo['postSite'];

    if (postSites is List) {
      for (final site in postSites) {
        if (site is Map && (site['_id'] ?? '').toString() == postSiteId) {
          return (site['siteName'] ?? 'Post Site').toString();
        }
      }
    }

    return "Post Site";
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
      await loadEvents();
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
      await loadEvents();
    }
  }

  void clearFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });

    loadEvents();
  }

  void viewEvent(Map<String, dynamic> event) {
    final postSiteId = (event['postSiteId'] ?? '').toString();
    final postSiteName = resolvePostSiteName(postSiteId);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            (event['title'] ?? 'Event').toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: "Post Site", value: postSiteName),
                _DetailRow(label: "Start", value: formatDate(event['start'])),
                _DetailRow(label: "End", value: formatDate(event['end'])),
                _DetailRow(label: "Created", value: formatDate(event['createdAt'])),
                const SizedBox(height: 12),
                const Text(
                  "Description",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (event['description'] ?? 'No description').toString(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Events",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
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
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickStartDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text("From: ${shortDate(startDate)}"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickEndDate,
                        icon: const Icon(Icons.calendar_month),
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
                    child: const Text("Clear Filter"),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                :events.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.3),
                          Colors.purpleAccent.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "No Events Found",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Your assigned events will appear here",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: loadEvents,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final postSiteId = (event['postSiteId'] ?? '').toString();
                  final postSiteName = resolvePostSiteName(postSiteId);

                  return InkWell(
                    onTap: () => viewEvent(event),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF2E2E2E),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3DFF).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.event_available,
                              color: Color(0xFF6D8DFF),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (event['title'] ?? 'Untitled Event').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  postSiteName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Created: ${formatDate(event['createdAt'])}",
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white38,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}