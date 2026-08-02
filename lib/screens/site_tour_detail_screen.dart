import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../global.dart' as g;
import '../session_data.dart';
import 'site_tour_nfc_scan_screen.dart';
import 'site_tour_qr_scan_screen.dart';

class SiteTourDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tour;
  final String postSiteId;
  final String postSiteName;

  const SiteTourDetailScreen({
    super.key,
    required this.tour,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<SiteTourDetailScreen> createState() => _SiteTourDetailScreenState();
}

class _SiteTourDetailScreenState extends State<SiteTourDetailScreen> {
  late Map<String, dynamic> tour;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    tour = Map<String, dynamic>.from(widget.tour);
  }

  Future<void> refreshTour() async {
    try {
      setState(() => isRefreshing = true);

      final companyId =
          SessionData.userProfile?['assignedCompanyID']?.toString() ?? '';
      final tourId = tour['_id']?.toString() ?? '';

      if (companyId.isEmpty || tourId.isEmpty) {
        if (mounted) setState(() => isRefreshing = false);
        return;
      }

      final url = Uri.parse(
        '${g.baseUrl}/api/site-tours/detail'
        '?companyId=$companyId&postSiteId=${widget.postSiteId}&tourId=$tourId',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          tour = Map<String, dynamic>.from(data['siteTour']);
          isRefreshing = false;
        });
      } else {
        setState(() => isRefreshing = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tourName = tour['tourName']?.toString() ?? 'Site Tour';
    final description = tour['description']?.toString() ?? '';
    final checkpoints = (tour['checkpoints'] as List?) ?? const [];
    final isNfcTour = checkpoints.any((cp) {
      final tag = cp['nfcTagValue']?.toString() ?? '';
      return tag.isNotEmpty;
    });

    final todayProgress = tour['todayProgress'] is Map
        ? Map<String, dynamic>.from(tour['todayProgress'] as Map)
        : null;
    final scannedCheckpoints =
        (todayProgress?['scannedCheckpoints'] as List?) ?? const [];
    final scannedIds = scannedCheckpoints
        .map((item) => item['checkpointId']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final completedCount = scannedIds.length;
    final totalCount = checkpoints.length;
    final completedToday = tour['completedToday'] == true;
    final isScheduledToday = tour['isScheduledToday'] == true;
    final canScan = isScheduledToday && !completedToday;
    final scanButtonText = isNfcTour
        ? 'Approach NFC Checkpoint'
        : 'Scan QR Code Checkpoint';
    final scanDescription = isNfcTour
        ? 'Approach the NFC tag with your phone to complete each checkpoint.'
        : 'Scan the QR code posted at each checkpoint to complete the tour.';
    final scanIcon = isNfcTour ? Icons.nfc_rounded : Icons.qr_code_scanner;

    String statusText;
    Color statusColor;
    if (!isScheduledToday) {
      statusText = 'No site tours scheduled.';
      statusColor = Colors.white70;
    } else if (completedToday) {
      statusText = 'Completed for today — come back tomorrow';
      statusColor = Colors.greenAccent;
    } else {
      statusText = '$completedCount / $totalCount completed today';
      statusColor = Colors.orangeAccent;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tourName),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : refreshTour,
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshTour,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: const Color(0xFF1E1F21),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tourName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: totalCount == 0 ? 0 : completedCount / totalCount,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        completedToday
                            ? 'Another daily tour will become available tomorrow.'
                            : scanDescription,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Checkpoints',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: checkpoints.isEmpty
                    ? const Center(
                        child: Text(
                          'No checkpoints available.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: checkpoints.length,
                        itemBuilder: (context, index) {
                          final checkpoint = checkpoints[index];
                          final checkpointId =
                              checkpoint['_id']?.toString() ?? '';
                          final name =
                              checkpoint['name']?.toString() ?? 'Checkpoint';
                          final order = checkpoint['order']?.toString() ??
                              (index + 1).toString();
                          final isCheckpointCompleted =
                              scannedIds.contains(checkpointId);
                          final requiresNfcWrite = isNfcTour &&
                              checkpoint['nfcWritten'] != true;

                          return Card(
                            color: const Color(0xFF1E1F21),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 17,
                                backgroundColor: isCheckpointCompleted
                                    ? Colors.green
                                    : Colors.grey.shade700,
                                child: isCheckpointCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        order,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                requiresNfcWrite
                                    ? 'NFC tag must be written by an administrator'
                                    : isCheckpointCompleted
                                        ? 'Completed today'
                                        : 'Pending today',
                                style: TextStyle(
                                  color: requiresNfcWrite
                                      ? Colors.redAccent
                                      : isCheckpointCompleted
                                          ? Colors.greenAccent
                                          : Colors.white54,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canScan ? Colors.deepOrange : Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              completedToday ? Icons.check_circle : scanIcon,
              color: Colors.white,
            ),
            label: Text(
              completedToday
                  ? 'Completed for Today'
                  : isScheduledToday
                      ? scanButtonText
                      : 'No Site Tour Scheduled',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: canScan
                ? () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isNfcTour
                            ? SiteTourNfcScanScreen(
                                postSiteId: widget.postSiteId,
                                postSiteName: widget.postSiteName,
                                tourId: tour['_id'].toString(),
                              )
                            : SiteTourQrScanScreen(
                                postSiteId: widget.postSiteId,
                                postSiteName: widget.postSiteName,
                                tourId: tour['_id'].toString(),
                              ),
                      ),
                    );

                    if (result == true) {
                      await refreshTour();
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
