import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';

class DARScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;

  const DARScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<DARScreen> createState() => _DARScreenState();
}

class _DARScreenState extends State<DARScreen> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);

  DateTime selectedDate = DateTime.now();
  bool loading = false;

  Map<String, dynamic>? summary;
  List<Map<String, dynamic>> activities = [];

  String get companyId {
    return (SessionData.companyInfo?['_id'] ??
        SessionData.userProfile?['assignedCompanyID'] ??
        '')
        .toString();
  }
  String get assignedPostSiteId {
    final user = SessionData.userProfile ?? {};

    final assignPost = user['assignPost'];

    if (assignPost is List && assignPost.isNotEmpty) {
      return (assignPost.first['postSiteID'] ??
          assignPost.first['postSiteId'] ??
          assignPost.first['_id'] ??
          '')
          .toString();
    }

    return (user['postSiteId'] ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    loadDAR();
  }

  Future<void> loadDAR() async {
    if (companyId.isEmpty) return;

    if (widget.postSiteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No post site found from this page.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final dateText = DateFormat('yyyy-MM-dd').format(selectedDate);

      final data = await api.getDAR(
        companyId: companyId,
        date: dateText,
        postSiteId: widget.postSiteId,
      );

      setState(() {
        summary = Map<String, dynamic>.from(data['summary'] ?? {});
        activities = (data['activities'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      debugPrint('DAR load error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load DAR: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });

    await loadDAR();
  }

  String formatTime(dynamic value) {
    if (value == null) return 'N/A';

    try {
      return DateFormat('hh:mm a').format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE, MMM d, yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        elevation: 0,
        title: const Text(
          'Daily Activity Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: loadDAR,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.postSiteName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (summary != null)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _summaryCard('Total', summary!['totalActivities']),
                    _summaryCard('Events', summary!['events']),
                    _summaryCard('Incidents', summary!['incidents']),
                    _summaryCard('Passdowns', summary!['passdowns']),
                    _summaryCard('WatchMode', summary!['watchModes']),
                    _summaryCard('TimeClock', summary!['timeClockRecords']),
                  ],
                ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Activity Summary',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (loading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (activities.isEmpty)
                _emptyState()
              else
                Column(
                  children: activities.map((item) {
                    return _activityCard(item);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          Text(
            '${value ?? 0}',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _typeBadge(item['type'] ?? 'Activity'),
              const Spacer(),
              Text(
                formatTime(item['time']),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item['guardName'] ?? 'Guard',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['postSiteName'] ?? 'N/A',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            item['description'] ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF123458),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Color(0xFF38BDF8),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, color: Colors.white38, size: 46),
          SizedBox(height: 10),
          Text(
            'No DAR activity found',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Activities for the selected date will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}