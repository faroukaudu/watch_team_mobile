import 'package:geolocator/geolocator.dart';

// import 'package:geolocator/geolocator.dart';

// Future<Position> determinePosition() async {
//   print("I amin second");
//   bool serviceEnabled;
//   LocationPermission permission;
//
//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     return Future.error('Location services are disabled.');
//   }
//
//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       return Future.error('Location permissions are denied.');
//     }
//   }
//
//   if (permission == LocationPermission.deniedForever) {
//     return Future.error('Location permissions are permanently denied.');
//   }
//
//   // ✅ use .timeout() instead of deprecated timeLimit
//   return await Geolocator.getCurrentPosition(
//     locationSettings: const LocationSettings(
//       accuracy: LocationAccuracy.high,
//     ),
//   ).timeout(const Duration(seconds: 10));
// }


Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}


/// Returns `true` if the device is within [radiusMeters] of [siteLat] & [siteLng].
Future<bool> isWithinSite({
  required double siteLat,
  required double siteLng,
  double radiusMeters = 500000000, // e.g., 50 meters proximity threshold
}) async {
  // 1. Ensure services and permissions
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw Exception('Location permissions are denied');
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied');
  }

  // 2. Get current device position
  final pos = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  // 3. Compute distance between points
  final distance = Geolocator.distanceBetween(
    pos.latitude,
    pos.longitude,
    siteLat,
    siteLng,
  );

  print('Current distance: ${distance.toStringAsFixed(2)} meters');

  // 4. Return whether within threshold
  return distance <= radiusMeters;
}


pressMe(){
  print("I AM Linking Here");
}