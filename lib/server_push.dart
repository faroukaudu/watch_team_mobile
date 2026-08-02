import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watch_team/global.dart' as g;
import 'screens/home.dart';
import 'package:watch_team/session_data.dart';

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
          'shiftTemplateId': SessionData.selectedShift?['_id']?.toString(),
          'shiftTitle': SessionData.selectedShift?['shiftTitle']?.toString(),
          'shiftStartTime': SessionData.selectedShift?['startTime']?.toString(),
          'shiftEndTime': SessionData.selectedShift?['endTime']?.toString(),
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
    required String postSiteId,
    required String clientId,
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
          'postSiteId': postSiteId,
          'clientId': clientId,
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
class ActiveGuardSessionApi {
  static Future<Map<String, dynamic>> fetchActiveSession({
    required String companyId,
    required String guardId,
  }) async {
    final url = Uri.parse('${g.baseUrl}/guard-active-session').replace(
      queryParameters: {'companyId': companyId, 'guardId': guardId},
    );
    final response = await http.get(url, headers: {'Accept': 'application/json'});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Unable to retrieve active session.');
    }
    SessionData.applyActiveSession(data['activeSession']);
    return data;
  }

  static Future<Map<String, dynamic>> clockIn({required String reportId}) async {
    final now = DateTime.now().toUtc();
    final response = await http.post(
      Uri.parse('${g.baseUrl}/clocking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reportId': reportId,
        'guardInfo': SessionData.userProfile,
        'clockInAt': now.toIso8601String(),
        'shiftTemplateId': SessionData.selectedShift?['_id']?.toString(),
        'shiftTitle': SessionData.selectedShift?['shiftTitle']?.toString(),
        'shiftStartTime': SessionData.selectedShift?['startTime']?.toString(),
        'shiftEndTime': SessionData.selectedShift?['endTime']?.toString(),
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (data['activeSession'] != null) SessionData.applyActiveSession(data['activeSession']);
      throw Exception(data['message'] ?? 'Unable to clock in.');
    }
    SessionData.applyActiveSession(data['activeSession']);
    return data;
  }

  static Future<Map<String, dynamic>> clockOut({required String reportId}) async {
    final response = await http.post(
      Uri.parse('${g.baseUrl}/clockingout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reportId': reportId,
        'guardInfo': SessionData.userProfile,
        'clockOutAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Unable to clock out.');
    }
    SessionData.applyActiveSession(data['activeSession']);
    if (data['companyInfo'] is Map) {
      SessionData.companyInfo = Map<String, dynamic>.from(data['companyInfo']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> updateBreak({
    required String reportId,
    required bool start,
  }) async {
    final response = await http.post(
      Uri.parse('${g.baseUrl}/clock-break'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reportId': reportId,
        'guardInfo': SessionData.userProfile,
        'action': start ? 'start' : 'end',
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Unable to update break.');
    }
    SessionData.applyActiveSession(data['activeSession']);
    return data;
  }
}
