import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watch_team/global.dart' as g;
import '../server_push.dart';
import 'screens/home.dart';

class TimeClockPush {

  // For Android emulator use 10.0.2.2 instead of localhost
  // For physical device: use your PC's LAN IP, e.g. 'http://192.168.1.10:3000'
  // static const String baseUrl = 'http://192.168.43.39:9000';

  static Future<Map<String, dynamic>> sendDataToServer({
    required String startTimer,
    required String stopTimer,
    required String checkedId,
    required String worktime,
    required String breaktime,
    required String docId,
    required userData,
    required companyData,
    // required String route,
  }) async {
    print("I ma in class");
    late String baseUrl = '${g.baseUrl}/work-report';

    final url = Uri.parse('$baseUrl');

    try {
      print("I am working here");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clockId':checkedId,
          'workt': worktime,
          'breakt': breaktime,
          'guardInfo':userData,
          'guardComp':companyData,
          'startT':startTimer,
          'stopT':stopTimer,
          'docId':docId,
        }),
      );

      if (response.statusCode == 200) {
        // Parse JSON
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print(data);

        // fetchUserProfile( data['guardID']);
        return data;
      } else {
        // Non-200 (error from server)
        throw Exception(
          'Server error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // Network / parsing error
      throw Exception('Request failed: $e');
    }
  }
}

class CheckInOut {

  // For Android emulator use 10.0.2.2 instead of localhost
  // For physical device: use your PC's LAN IP, e.g. 'http://192.168.1.10:3000'
  // static const String baseUrl = 'http://192.168.43.39:9000';

  static Future<Map<String, dynamic>> checkIntoServer({
    // required String worktime,
    // required String breaktime,
    required String checkInTime,
    required userData,
    required companyData,
    // required String route,
  }) async {
    print("I ma in class");
    late String baseUrl = '${g.baseUrl}/checking';

    final url = Uri.parse('$baseUrl');

    try {
      print("I am working here");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'time':checkInTime,
          'guardInfo':userData,
          'guardComp':companyData,
        }),
      );

      if (response.statusCode == 200) {
        // Parse JSON
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print(data);
        return data;
      } else {
        // Non-200 (error from server)
        throw Exception(
          'Server error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // Network / parsing error
      throw Exception('Request failed: $e');
    }
  }
}

class CheckOut {

  // For Android emulator use 10.0.2.2 instead of localhost
  // For physical device: use your PC's LAN IP, e.g. 'http://192.168.1.10:3000'
  // static const String baseUrl = 'http://192.168.43.39:9000';

  static Future<Map<String, dynamic>> checkIntoServer({
    // required String worktime,
    // required String breaktime,
    required String checkId,
    required userData,
    required String checkoutTime,
    // required String route,
  }) async {
    print("I ma in class");
    // late String baseUrl = 'http://192.168.43.39:9000/checkingout';
    late String baseUrl = '${g.baseUrl}/checkingout';

    final url = Uri.parse('$baseUrl');

    try {
      print("I am working here");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'dbId':checkId,
          'guardInfo':userData,
          'checkouttime':checkoutTime,
        }),
      );

      if (response.statusCode == 200) {
        // Parse JSON
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print(data);
        return data;
      } else {
        // Non-200 (error from server)
        throw Exception(
          'Server error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // Network / parsing error
      throw Exception('Request failed: $e');
    }
  }
}