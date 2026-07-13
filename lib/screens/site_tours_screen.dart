import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../global.dart' as g;
import '../session_data.dart';
import 'site_tour_qr_scan_screen.dart';
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
  List tours = [];

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

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          tours = data['tours'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Unable to load site tours.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to connect to server.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Site Tours'),
        backgroundColor: Colors.black,
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
          : tours.isEmpty
          ? const Center(
        child: Text(
          'No site tours available.',
          style: TextStyle(color: Colors.white),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tours.length,
        itemBuilder: (context, index) {
          final tour = tours[index];

          final tourName =
          (tour['tourName'] ?? 'Site Tour').toString();

          final checkpoints =
              (tour['checkpoints'] as List?)?.length ?? 0;
          final checkpointList = (tour['checkpoints'] as List?) ?? [];

          final bool isNfcTour = checkpointList.any((cp) {
            final tag = cp['nfcTagValue']?.toString() ?? '';
            return tag.isNotEmpty && tag != 'PENDING';
          });

          final String tourType = isNfcTour ? 'NFC' : 'QR Code';
          final IconData tourIcon = isNfcTour ? Icons.nfc_rounded : Icons.qr_code_2;
          final Color badgeColor = isNfcTour ? Colors.green : Colors.deepOrange;

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
                      tour['tourName'] ?? 'Unnamed Tour',
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
                        Icon(
                          tourIcon,
                          size: 13,
                          color: badgeColor,
                        ),
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
              subtitle: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$checkpoints checkpoints',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SiteTourDetailScreen(
                      tour: Map<String, dynamic>.from(tour),
                      postSiteId: widget.postSiteId,
                      postSiteName: widget.postSiteName,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}