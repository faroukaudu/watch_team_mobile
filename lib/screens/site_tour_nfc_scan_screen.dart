import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';

import '../global.dart' as g;
import '../session_data.dart';

class SiteTourNfcScanScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;
  final String tourId;

  const SiteTourNfcScanScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
    required this.tourId,
  });

  @override
  State<SiteTourNfcScanScreen> createState() => _SiteTourNfcScanScreenState();
}

class _SiteTourNfcScanScreenState extends State<SiteTourNfcScanScreen> {
  bool isProcessing = false;
  bool isAvailable = false;
  String scanMessage = 'Approach the NFC tag to your phone.';
  int completedCount = 0;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    startNfcSession();
  }

  Future<void> startNfcSession() async {
    final available = await NfcManager.instance.isAvailable();

    print("NFC AVAILABLE: $available");

    if (!mounted) return;

    setState(() {
      isAvailable = available;
      scanMessage = available
          ? 'NFC is ready. Hold the phone close to the NFC checkpoint tag.'
          : 'NFC is not available on this device.';
    });

    if (!available) return;

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        print("NFC TAG DETECTED");
        print(tag.data);

        if (isProcessing) return;

        setState(() {
          isProcessing = true;
          scanMessage = 'NFC tag detected. Processing...';
        });

        try {
          final rawValue = readTextFromTag(tag);

          print("NFC RAW VALUE: $rawValue");

          if (rawValue == null || rawValue.isEmpty) {
            setState(() {
              scanMessage = 'Unable to read Watch Team NFC tag.';
              isProcessing = false;
            });
            return;
          }

          await processNfcTag(rawValue);
        } catch (e) {
          print("NFC READ ERROR: $e");

          setState(() {
            scanMessage = 'Unable to process NFC tag.';
            isProcessing = false;
          });
        }
      },
    );
  }

  String? readTextFromTag(NfcTag tag) {
    final ndef = Ndef.from(tag);

    if (ndef == null || ndef.cachedMessage == null) {
      return null;
    }

    final records = ndef.cachedMessage!.records;

    if (records.isEmpty) return null;

    final payload = records.first.payload;

    if (payload.isEmpty) return null;

    final languageCodeLength = payload.first;
    final textBytes = payload.sublist(1 + languageCodeLength);

    return utf8.decode(textBytes);
  }

  Future<void> processNfcTag(String rawCode) async {
    final parts = rawCode.split('|');

    String scannedTourId = '';
    String checkpointId = '';

    if (parts.length == 3 && parts[0] == 'WT_NFC_TOUR') {
      scannedTourId = parts[1];
      checkpointId = parts[2];
    } else if (parts.length == 4 && parts[0] == 'WATCHTEAM' && parts[1] == 'TOUR') {
      scannedTourId = parts[2];
      checkpointId = parts[3];
    } else {
      setState(() {
        scanMessage = 'Invalid Watch Team NFC tag.';
        isProcessing = false;
      });
      return;
    }

    if (scannedTourId != widget.tourId) {
      setState(() {
        scanMessage = 'This NFC tag does not belong to the selected tour.';
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong NFC tag for this tour.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final companyId =
        SessionData.userProfile?['assignedCompanyID']?.toString() ?? '';

    final guardId = SessionData.userProfile?['_id']?.toString() ?? '';

    final guardName =
        SessionData.userProfile?['fullname']?.toString() ??
            SessionData.userProfile?['username']?.toString() ??
            '';

    final response = await http.post(
      Uri.parse('${g.baseUrl}/api/site-tours/nfc-scan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'companyId': companyId,
        'postSiteId': widget.postSiteId,
        'tourId': widget.tourId,
        'checkpointId': checkpointId,
        'guardId': guardId,
        'guardName': guardName,
        'nfcTagValue': rawCode,
        'latitude': '',
        'longitude': '',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        completedCount = data['completedCount'] ?? 0;
        totalCount = data['totalCount'] ?? 0;
        scanMessage = data['message'] ?? 'NFC checkpoint scanned.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanMessage),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        scanMessage = data['message'] ?? 'Unable to process NFC tag.';
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressText = totalCount > 0
        ? '$completedCount / $totalCount completed'
        : 'No checkpoint scanned yet';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan NFC Tag'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.nfc_rounded,
                color: isAvailable ? Colors.greenAccent : Colors.white54,
                size: 90,
              ),
              const SizedBox(height: 20),
              Text(
                scanMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hold the phone close to the NFC checkpoint tag.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Text(
                progressText,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
              if (isProcessing) ...[
                const SizedBox(height: 18),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}