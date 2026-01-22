// lib/screens/report/all_report.dart
import 'package:flutter/material.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/screens/report/report_detail_screen.dart';

class AllReports extends StatefulWidget {
  const AllReports({super.key});

  @override
  State<AllReports> createState() => _AllReportsState();
}

class _AllReportsState extends State<AllReports> {

  Future<void> _onRefresh() async {
    await loadReports();
  }

  int tabIndex = 0; // 0 = All, 1 = My
  bool loading = true;

  List<Map<String, dynamic>> allReports = [];
  List<Map<String, dynamic>> myReports = [];

  late final ApiClient api;
  late final String myUserId;

  @override
  void initState() {
    super.initState();

    // ✅ Your backend IP
    api = ApiClient(baseUrl: 'http://192.168.32.39:9000');

    final profile = SessionData.userProfile ?? <String, dynamic>{};
    myUserId = (profile['_id'] ?? profile['id'] ?? '').toString();

    loadReports();
  }

  Future<void> loadReports({String q = ''}) async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      allReports = await api.listReports(q: q, scope: 'all');

      myReports = myUserId.isEmpty
          ? []
          : await api.listReports(q: q, scope: 'my', userId: myUserId);

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
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
            onPressed: () => Navigator.maybePop(context),
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
              : (data.isEmpty)
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

              final badge = _badgeForTitle(title);

              return _ReportCard(
                title: title,
                createdAtIso: createdAt,
                badge: badge,
                incidentType: _incidentTypeFromTitle(title),
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

                  // refresh when coming back
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

  static _Badge _badgeForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('break') || t.contains('incident')) {
      return const _Badge('INCIDENT', Color(0xFFFF3D00));
    }
    if (t.contains('fire') || t.contains('incident')) {
      return const _Badge('INCIDENT', Color(0xFFFF3D00));
    }
    if (t.contains('inspection') || t.contains('hourly')) {
      return const _Badge('STANDARD', Color(0xFF00C853));
    }
    return const _Badge('GENERAL', Color(0xFF9E9E9E));
  }

  static String _incidentTypeFromTitle(String title) {
    final t = title.toLowerCase();

    if (t.contains('break') || t.contains('incident')) return 'Incident Report';
    if (t.contains('inspection')) return 'Inspection Report';
    if (t.contains('hourly')) return 'Hourly Report';

    return 'General Report';
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
  final String incidentType;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.createdAtIso,
    required this.badge,
    required this.incidentType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(createdAtIso)?.toLocal();
    final when = dt == null ? '' : _fmt(dt);

    return InkWell(
      onTap: onTap,
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
            // TITLE + BADGE
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: badge.color),
                  ),
                  child: Text(
                    badge.text,
                    style: TextStyle(
                      color: badge.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // incident type + time
            Row(
              children: [
                Icon(Icons.local_offer,
                    size: 16, color: Colors.white.withOpacity(0.65)),
                const SizedBox(width: 6),
                Text(
                  incidentType,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule,
                    size: 16, color: Colors.white.withOpacity(0.65)),
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
