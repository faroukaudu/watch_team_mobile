// lib/screens/report/all_report.dart
import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/screens/report/report_detail_screen.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/session_data.dart';

class AllReports extends StatefulWidget {
  const AllReports({super.key});

  @override
  State<AllReports> createState() => _AllReportsState();
}

class _AllReportsState extends State<AllReports> {
  int tabIndex = 0; // 0 = All, 1 = My
  bool loading = true;

  List<Map<String, dynamic>> allReports = [];
  List<Map<String, dynamic>> myReports = [];

  late final ApiClient api;
  late final String myUserId;

  @override
  void initState() {
    super.initState();

    api = ApiClient(baseUrl: '${g.baseUrl}');

    final profile = SessionData.userProfile ?? <String, dynamic>{};
    myUserId = (profile['_id'] ?? profile['id'] ?? '').toString();

    loadReports();
  }

  Future<void> _onRefresh() async {
    await loadReports();
  }

  Future<void> loadReports({String q = ''}) async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      allReports = await api.listReports(q: q, scope: 'all');

      myReports = myUserId.isEmpty
          ? []
          : await api.listReports(q: q, scope: 'my', userId: myUserId);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  _Badge _badgeForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'standard':
        return const _Badge('STANDARD', Color(0xFF00C853));
      case 'incident':
        return const _Badge('INCIDENT', Color(0xFFFF9800));
      case 'general':
        return const _Badge('GENERAL', Color(0xFF9E9E9E));
      case 'log':
        return const _Badge('LOG', Color(0xFF607D8B));
      case 'nfc':
        return const _Badge('NFC', Color(0xFF9C27B0));
      default:
        return const _Badge('GENERAL', Color(0xFF9E9E9E));
    }
  }

  String _displayTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'standard':
        return 'Standard Report';
      case 'incident':
        return 'Incident Report';
      case 'general':
        return 'General Report';
      case 'log':
        return 'Log Report';
      case 'nfc':
        return 'NFC Report';
      default:
        return 'General Report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = (tabIndex == 0) ? allReports : myReports;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B0B0B),
          elevation: 0,
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
          centerTitle: true,
          title: const Text(
            'Reports',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _TabsPill(
                onTabChanged: (idx) => setState(() => tabIndex = idx),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: const Color(0xFFFF4D4D),
          backgroundColor: const Color(0xFF171717),
          onRefresh: _onRefresh,
          child: loading
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 280),
              Center(child: CircularProgressIndicator()),
            ],
          )
              : data.isEmpty
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 240),
              _EmptyReportsState(),
            ],
          )
              : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final r = data[i];
              final id = (r['_id'] ?? '').toString();
              final title = (r['title'] ?? 'Report').toString();
              final createdAt = (r['createdAt'] ?? '').toString();
              final category =
              (r['category'] ?? 'general').toString();

              final badge = _badgeForCategory(category);
              final reportType = _displayTypeFromCategory(category);

              return _ReportCard(
                title: title,
                createdAtIso: createdAt,
                badge: badge,
                reportType: reportType,
                onTap: () async {
                  if (id.isEmpty) return;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(
                        reportId: id,
                        title: title,
                        api: api,
                      ),
                    ),
                  );

                  loadReports();
                },
              );
            },
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true)
                    .pushNamed('/select_report');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3DFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabsPill extends StatelessWidget {
  final ValueChanged<int> onTabChanged;

  const _TabsPill({required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TabBar(
        onTap: onTabChanged,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelColor: const Color(0xFFFF4D4D),
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: 'All Reports'),
          Tab(text: 'My Reports'),
        ],
      ),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No Report Available',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String createdAtIso;
  final _Badge badge;
  final String reportType;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.createdAtIso,
    required this.badge,
    required this.reportType,
    required this.onTap,
  });

  Color _badgeBackground(Color color, String text) {
    if (text.toLowerCase() == 'general') {
      return const Color(0xFF1A1A1A);
    }
    return color.withOpacity(0.16);
  }

  Color _badgeBorder(Color color, String text) {
    if (text.toLowerCase() == 'general') {
      return const Color(0xFF3A3A3A);
    }
    return color.withOpacity(0.55);
  }

  Color _badgeText(Color color, String text) {
    if (text.toLowerCase() == 'general') {
      return Colors.white;
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(createdAtIso)?.toLocal();
    final when = dt == null ? '' : _fmt(dt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2F35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBackground(badge.color, badge.text),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _badgeBorder(badge.color, badge.text),
                      ),
                    ),
                    child: Text(
                      badge.text,
                      style: TextStyle(
                        color: _badgeText(badge.color, badge.text),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.local_offer,
                  size: 16,
                  color: Colors.white.withOpacity(0.65),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reportType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.white.withOpacity(0.65),
                ),
                const SizedBox(width: 6),
                Text(
                  when,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _Badge {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);
}