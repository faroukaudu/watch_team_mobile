import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../global.dart' as g;
import '../session_data.dart';


class SiteTourQrScanScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;
  final String tourId;

  const SiteTourQrScanScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
    required this.tourId,
  });

  @override
  State<SiteTourQrScanScreen> createState() => _SiteTourQrScanScreenState();
}

class _SiteTourQrScanScreenState extends State<SiteTourQrScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  bool isProcessing = false;
  String scanMessage = 'Scan a site tour QR checkpoint';
  int completedCount = 0;
  int totalCount = 0;

  Future<void> processQrCode(String rawCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      scanMessage = 'Processing QR tag...';
    });

    try {
      final parts = rawCode.split('|');

      if (parts.length != 3 || parts[0] != 'WT_TOUR') {
        setState(() {
          scanMessage = 'Invalid site tour QR tag.';
          isProcessing = false;
        });
        return;
      }

      final scannedTourId = parts[1];
      final checkpointId = parts[2];

      if (scannedTourId != widget.tourId) {
        setState(() {
          scanMessage = 'This QR tag does not belong to the selected tour.';
          isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wrong QR tag for this tour.'),
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

      if (companyId.isEmpty || guardId.isEmpty) {
        setState(() {
          scanMessage = 'Guard session not found. Please log in again.';
          isProcessing = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${g.baseUrl}/api/site-tours/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'companyId': companyId,
          'postSiteId': widget.postSiteId,
          'tourId': widget.tourId,
          'checkpointId': checkpointId,
          'guardId': guardId,
          'guardName': guardName,
          'qrCodeValue': rawCode,
          'latitude': '',
          'longitude': '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // if (await Vibration.hasVibrator() ?? false) {
        //   Vibration.vibrate(duration: 180);
        // }

        setState(() {
          completedCount = data['completedCount'] ?? 0;
          totalCount = data['totalCount'] ?? 0;
          scanMessage = data['message'] ?? 'Checkpoint scanned.';
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

        return;
      } else {
        setState(() {
          scanMessage = data['message'] ?? 'Unable to process QR tag.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(scanMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        scanMessage = 'Unable to connect to server.';
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to connect to server.')),
      );
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
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
        title: const Text('Scan QR Tag'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;

                if (barcodes.isEmpty) return;

                final value = barcodes.first.rawValue;

                if (value == null || value.isEmpty) return;

                processQrCode(value);
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              color: const Color(0xFF1E1F21),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    scanMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    progressText,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 14),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}