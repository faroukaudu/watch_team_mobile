import 'package:flutter/material.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/widgets/report_field_card.dart';
import 'package:watch_team/widgets/report_attachment_card.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  final String title;
  final ApiClient api;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.title,
    required this.api,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool loading = true;
  Map<String, dynamic>? report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = await widget.api.getReportById(widget.reportId);
      setState(() => report = r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load report: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (report == null)
          ? const Center(
        child: Text('No report found', style: TextStyle(color: Colors.white)),
      )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final createdAt = (report!['createdAt'] ?? '').toString();
    final fullname = (report!['fullname'] ?? '').toString();
    final companyID = (report!['companyID'] ?? '').toString();

    final fields = (report!['fields'] is Map)
        ? Map<String, dynamic>.from(report!['fields'])
        : <String, dynamic>{};

    final attachments = _parseAttachments(report!['attachments']);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(
            title: widget.title,
            createdAtIso: createdAt,
            fullname: fullname,
            companyId: companyID,
          ),
          const SizedBox(height: 14),

          const Text(
            'Details',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          if (fields.isEmpty)
            Text('No fields', style: TextStyle(color: Colors.white.withOpacity(0.6)))
          else
            ...fields.entries
                .where((e) => !('${e.value}'.toLowerCase().contains('res.cloudinary.com')))
                .map((e) => ReportFieldCard(label: e.key, value: '${e.value}')),

          const SizedBox(height: 16),

          const Text(
            'Attachments',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          if (attachments.isEmpty)
            Text('No attachments', style: TextStyle(color: Colors.white.withOpacity(0.6)))
          else
            ...attachments.map((a) => ReportAttachmentCard(attachment: a)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parseAttachments(dynamic raw) {
    final List<Map<String, dynamic>> out = [];
    if (raw is! List) return out;

    for (final a in raw) {
      if (a is Map) {
        out.add(Map<String, dynamic>.from(a));
      } else if (a is String) {
        out.add({'secureUrl': a});
      }
    }
    return out;
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String createdAtIso;
  final String fullname;
  final String companyId;

  const _HeaderCard({
    required this.title,
    required this.createdAtIso,
    required this.fullname,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(createdAtIso)?.toLocal();
    final when = dt == null ? '' : _fmt(dt);

    final badge = _badgeForTitle(title);

    return Container(
      width: double.infinity,
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
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badge.color),
                ),
                child: Text(
                  badge.text,
                  style: TextStyle(color: badge.color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetaRow(icon: Icons.schedule, label: 'Time', value: when),
          if (fullname.isNotEmpty) _MetaRow(icon: Icons.person, label: 'Reporter', value: fullname),
          if (companyId.isNotEmpty) _MetaRow(icon: Icons.business, label: 'Company ID', value: companyId),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  static _Badge _badgeForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('break') || t.contains('incident')) return const _Badge('INCIDENT', Color(0xFFFF3D00));
    if (t.contains('inspection') || t.contains('hourly')) return const _Badge('STANDARD', Color(0xFF00C853));
    return const _Badge('GENERAL', Color(0xFF9E9E9E));
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w800)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _Badge {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
}
