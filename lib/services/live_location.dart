import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LiveLocationService {
  StreamSubscription<Position>? _sub;
  bool _sending = false;

  Future<void> start({
    required String baseUrl,   // e.g. http://192.168.32.39:9000  OR https://yourdomain.com
    required String companyId,
    required String guardId,
    required String guardName,
  }) async {
    // 1) Ensure permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception("Location permission denied forever.");
    }

    // 2) Tell server: guard is ONLINE (so web can restore marker)
    await _postJson(
      "$baseUrl/api/guard/checkin",
      {
        "companyId": companyId,
        "guardId": guardId,
        "guardName": guardName,
        "ts": DateTime.now().millisecondsSinceEpoch,
      },
    );

    // 3) Send ONE immediate location (so pin appears immediately after check-in)
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await _sendLocation(
      baseUrl: baseUrl,
      companyId: companyId,
      guardId: guardId,
      guardName: guardName,
      pos: pos,
    );

    // 4) Start streaming updates
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // sends only when moved 10m
      ),
    ).listen((pos) async {
      if (_sending) return;
      _sending = true;

      try {
        await _sendLocation(
          baseUrl: baseUrl,
          companyId: companyId,
          guardId: guardId,
          guardName: guardName,
          pos: pos,
        );
      } finally {
        _sending = false;
      }
    });
  }

  Future<void> stop({
    required String baseUrl,
    required String companyId,
    required String guardId,
  }) async {
    // 1) stop stream
    await _sub?.cancel();
    _sub = null;

    // 2) tell server: guard is OFFLINE (so web removes marker)

    if (companyId.isNotEmpty && guardId.isNotEmpty) {
      await _postJson(
        "$baseUrl/api/guard/checkout",
        {
          "companyId": companyId,
          "guardId": guardId,
          "ts": DateTime.now().millisecondsSinceEpoch,
        },
      );
    }

  }

  Future<void> _sendLocation({
    required String baseUrl,
    required String companyId,
    required String guardId,
    required String guardName,
    required Position pos,
  }) async {
    await _postJson(
      "$baseUrl/api/guard/location",
      {
        "companyId": companyId,
        "guardId": guardId,
        "guardName": guardName,
        "lat": pos.latitude,
        "lng": pos.longitude,
        "speed": pos.speed,
        "heading": pos.heading,
        "accuracy": pos.accuracy,
        "ts": DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> _postJson(String url, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    // Optional: log errors (helps debugging)
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print("POST failed $url -> ${res.statusCode}: ${res.body}");
    }
  }
}
