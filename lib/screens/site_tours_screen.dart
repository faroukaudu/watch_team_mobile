import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../global.dart' as g;
import '../session_data.dart';
import 'site_tour_detail_screen.dart';

class SiteToursScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;

  const SiteToursScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<SiteToursScreen> createState() => _SiteToursScreenState();
}

class _SiteToursScreenState extends State<SiteToursScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> tours = [];

  @override
  void initState() {
    super.initState();
    fetchTours();
  }

  Future<void> fetchTours() async {
    try {
      final companyId =
          SessionData.userProfile?['assignedCompanyID']?.toString() ?? '';

      final url = Uri.parse(
        '${g.baseUrl}/api/site-tours'
        '?companyId=$companyId&postSiteId=${widget.postSiteId}',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          tours = data['tours'] ?? [];
          errorMessage = null;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Unable to load site tours.';
          isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Unable to connect to server.';
        isLoading = false;
      });
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'N/A';
    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return 'N/A';
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} $hour:$minute $period';
  }

  List<Map<String, dynamic>> _historyRows() {
    final rows = <Map<String, dynamic>>[];

    for (final rawTour in tours) {
      final tour = Map<String, dynamic>.from(rawTour as Map);
      final progress = (tour['progress'] as List?) ?? const [];

      for (final rawProgress in progress) {
        final item = Map<String, dynamic>.from(rawProgress as Map);
        rows.add({
          'tourName': tour['tourName']?.toString() ?? 'Site Tour',
          ...item,
        });
      }
    }

    rows.sort((a, b) {
      final aDate = DateTime.tryParse(a['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return rows;
  }

  void _showHistory() {
    final rows = _historyRows();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF17181A),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Site Tour History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: rows.isEmpty
                        ? const Center(
                            child: Text(
                              'No completed or in-progress tours yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                dataTextStyle: const TextStyle(color: Colors.white70),
                                columns: const [
                                  DataColumn(label: Text('Tour')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Date & Time')),
                                  DataColumn(label: Text('Guard')),
                                ],
                                rows: rows.map((row) {
                                  final completed = row['status'] == 'Completed';
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(row['tourName']?.toString() ?? 'Site Tour')),
                                      DataCell(
                                        Text(
                                          row['status']?.toString() ?? 'In Progress',
                                          style: TextStyle(
                                            color: completed
                                                ? Colors.greenAccent
                                                : Colors.orangeAccent,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(_formatDateTime(
                                        row['completedAt'] ?? row['startedAt'],
                                      ))),
                                      DataCell(Text(row['guardName']?.toString() ?? 'Guard')),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduledTours = tours.where((rawTour) {
      final tour = Map<String, dynamic>.from(rawTour as Map);
      return tour['isScheduledToday'] == true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Site Tours'),
        backgroundColor: Colors.black,
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              tooltip: 'History',
              onPressed: _showHistory,
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: fetchTours,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : scheduledTours.isEmpty
                  ? const Center(
                      child: Text(
                        'No site tours scheduled.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchTours,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: scheduledTours.length,
                        itemBuilder: (context, index) {
                          final tour = Map<String, dynamic>.from(
                            scheduledTours[index] as Map,
                          );
                          final checkpointList =
                              (tour['checkpoints'] as List?) ?? const [];
                          final checkpoints = checkpointList.length;
                          final isNfcTour = checkpointList.any((cp) {
                            final tag = cp['nfcTagValue']?.toString() ?? '';
                            return tag.isNotEmpty;
                          });
                          final completedToday = tour['completedToday'] == true;
                          final todayStatus =
                              tour['todayStatus']?.toString() ?? 'Not Started';
                          final tourType = isNfcTour ? 'NFC' : 'QR Code';
                          final tourIcon =
                              isNfcTour ? Icons.nfc_rounded : Icons.qr_code_2;
                          final badgeColor =
                              isNfcTour ? Colors.green : Colors.deepOrange;

                          return Card(
                            color: const Color(0xFF1E1F21),
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tour['tourName']?.toString() ?? 'Unnamed Tour',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: badgeColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(tourIcon, size: 13, color: badgeColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          tourType,
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        completedToday
                                            ? 'Completed for today — come back tomorrow'
                                            : todayStatus,
                                        style: TextStyle(
                                          color: completedToday
                                              ? Colors.greenAccent
                                              : Colors.orangeAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$checkpoints checkpoints',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white54,
                                size: 16,
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SiteTourDetailScreen(
                                      tour: tour,
                                      postSiteId: widget.postSiteId,
                                      postSiteName: widget.postSiteName,
                                    ),
                                  ),
                                );
                                await fetchTours();
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
