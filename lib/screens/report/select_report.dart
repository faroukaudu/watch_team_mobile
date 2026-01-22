import 'package:flutter/material.dart';
import 'package:watch_team/screens/report/send_report.dart';

/// Select Report screen with a working search bar (filters by report title).
class SelectReportScreen extends StatefulWidget {
  const SelectReportScreen({super.key});

  @override
  State<SelectReportScreen> createState() => _SelectReportScreenState();
}

class _SelectReportScreenState extends State<SelectReportScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<ReportItem> _allReports = const [
    ReportItem(
      title: 'Break-In',
      subtitle: 'This report covers break-in incident.',
      type: ReportType.incident,
    ),
    ReportItem(
      title: 'Detailed Incident Report',
      subtitle: 'Detailed Incident Report',
      type: ReportType.incident,
    ),
    ReportItem(
      title: 'Equipment Inspection Report',
      subtitle: 'Equipment Inspection Report',
      type: ReportType.standard,
    ),
    ReportItem(
      title: 'Fire Alarm',
      subtitle: 'This report is created to address fire alarm.',
      type: ReportType.incident,
    ),
    ReportItem(
      title: 'General Incident report',
      subtitle: 'General incident report with an option to select any incident',
      type: ReportType.incident,
    ),
    ReportItem(
      title: 'Hourly Report',
      subtitle: 'Hourly Report',
      type: ReportType.standard,
    ),
    ReportItem(
      title: 'Parking Violation',
      subtitle: 'This report is used to check for parking Violation',
      type: ReportType.incident,
    ),
    ReportItem(
      title: 'Police On Site',
      subtitle: 'This cover the Police Report',
      type: ReportType.incident,
    ),
    ReportItem(
      title: 'Trespassing',
      subtitle: 'This report shows Trespassing Incidents',
      type: ReportType.incident,
    ),
    ReportItem(
      title: 'Vehicle Inspection Report',
      subtitle: 'Shows Report of the Vehicle Inspected',
      type: ReportType.standard,
    ),
  ];

  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ReportItem> get _filtered {
    if (_query.isEmpty) return _allReports;
    final q = _query.toLowerCase();
    return _allReports.where((r) => r.title.toLowerCase().contains(q)).toList();
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
        title: const Text(
          'Select Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              _SearchBar(
                controller: _searchCtrl,
                onClear: () => _searchCtrl.clear(),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _filtered.isEmpty
                    ? const _EmptyResult()
                    : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    return ReportCard(
                      item: item,
                      onTap: () {
                        // TODO: return selected report or navigate
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportFormScreen(reportTitle: item.title),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search here...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Container(
            width: 58,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                // Search is already live via listener.
                // This button can optionally close keyboard:
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final ReportItem item;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = _TypeChip(type: item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2F35),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            chip,
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ReportType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final bool isIncident = type == ReportType.incident;

    final bg = isIncident ? const Color(0xFFF1C6C9) : const Color(0xFF0F3B3A);
    final fg = isIncident ? const Color(0xFF7A1C22) : const Color(0xFF69C1B8);
    final text = isIncident ? 'Incident' : 'Standard';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No reports match your search.',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
    );
  }
}

enum ReportType { incident, standard }

class ReportItem {
  final String title;
  final String subtitle;
  final ReportType type;

  const ReportItem({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}
