import 'package:dio/dio.dart';
import 'package:watch_team/session_data.dart';
import 'package:intl/intl.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({
    required String baseUrl,
    String apiPrefix = '',
    Dio? dio,
  }) : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: '$baseUrl$apiPrefix',
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  Future<String> createReport({
    required String title,
    required Map<String, dynamic> fields,
    String? templateId,
  }) async {
    final res = await _dio.post('/reports', data: {
      'title': title,
      'fields': fields,
      'templateId': templateId,
      'userInfo': SessionData.userProfile,
      'companyInfo': SessionData.companyInfo,
    });

    final data = res.data;
    if (data is Map) {
      final rid = data['reportId'];
      if (rid != null && rid.toString().isNotEmpty && rid.toString() != 'null') {
        return rid.toString();
      }

      final alt = data['id'] ?? data['_id'];
      if (alt != null && alt.toString().isNotEmpty && alt.toString() != 'null') {
        return alt.toString();
      }
    }

    throw Exception('createReport() did not return reportId. Response: $data');
  }

  Future<Map<String, dynamic>> getCloudinarySign({
    required String reportId,
    required String kind,
  }) async {
    final res = await _dio.post('/uploads/cloudinary-sign', data: {
      'reportId': reportId,
      'kind': kind,
    });

    if (res.data is Map) return Map<String, dynamic>.from(res.data);
    throw Exception('Unexpected getCloudinarySign response: ${res.data}');
  }

  Future<void> saveAttachmentRef({
    required String reportId,
    required Map<String, dynamic> payload,
  }) async {
    await _dio.post('/reports/$reportId/attachments', data: payload);
  }

  Future<List<Map<String, dynamic>>> listReports({
    String q = '',
    String scope = 'all',
    String? userId,
  }) async {
    final companyId =
    (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();

    final res = await _dio.get('/reports', queryParameters: {
      'limit': 100,
      'scope': scope,
      'companyId': companyId,
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (scope == 'my' && (userId ?? '').isNotEmpty) 'userId': userId,
    });

    final data = res.data as Map;
    final items = (data['items'] as List).cast<dynamic>();
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getReportById(String id) async {
    final res = await _dio.get('/reports/$id');
    final data = res.data;

    if (data is Map && data['report'] is Map) {
      return Map<String, dynamic>.from(data['report'] as Map);
    }

    if (data is Map && data['_id'] != null) {
      return Map<String, dynamic>.from(data as Map);
    }

    throw Exception('Unexpected response for GET /reports/$id: $data');
  }

  Future<List<Map<String, dynamic>>> listReportTemplates() async {
    final companyId =
    (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();

    final res = await _dio.get('/report-templates', queryParameters: {
      'companyId': companyId,
    });

    final data = res.data as Map;
    final items = (data['items'] as List).cast<dynamic>();
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getReportTemplate(String templateId) async {
    final companyId =
    (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();

    final res = await _dio.get(
      '/report-templates/$templateId',
      queryParameters: {
        'companyId': companyId,
      },
    );

    final data = res.data as Map;

    if (data['template'] is Map) {
      return Map<String, dynamic>.from(data['template'] as Map);
    }

    throw Exception(
        'Unexpected response for GET /report-templates/$templateId');
  }

//   NOtes
  Future<Map<String, dynamic>> createNote({
    required String companyID,
    required String postSiteID,
    required String postSiteName,
    required String guardID,
    required String guardName,
    required String title,
    required String note,
  }) async {
    final res = await _dio.post('/api/notes', data: {
      'companyID': companyID,
      'postSiteID': postSiteID,
      'postSiteName': postSiteName,
      'guardID': guardID,
      'guardName': guardName,
      'title': title,
      'note': note,
    });

    final data = res.data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected response for POST /api/notes: $data');
  }

  Future<List<Map<String, dynamic>>> listGuardNotes({
    required String companyID,
    required String guardID,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _dio.get('/api/notes/guard/$guardID', queryParameters: {
      'companyID': companyID,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    });

    final data = res.data;

    if (data is Map && data['notes'] is List) {
      return (data['notes'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected response for GET /api/notes/guard/$guardID: $data');
  }

  Future<Map<String, dynamic>> updateNote({
    required String noteID,
    required String title,
    required String note,
  }) async {
    final res = await _dio.put('/api/notes/$noteID', data: {
      'title': title,
      'note': note,
    });

    final data = res.data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected response for PUT /api/notes/$noteID: $data');
  }

  Future<List<Map<String, dynamic>>> listGuardEvents({
    required String companyId,
    required String guardId,
    required List<String> postSiteIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _dio.get('/api/mobile/events', queryParameters: {
      'companyId': companyId,
      'guardId': guardId,
      if (postSiteIds.isNotEmpty) 'postSiteIds': postSiteIds.join(','),
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    });

    final data = res.data;

    if (data is Map && data['events'] is List) {
      return (data['events'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected response for GET /api/mobile/events: $data');
  }


  Future<List<Map<String, dynamic>>> listGuardDispatch({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final companyId = (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
    final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

    final res = await _dio.get('/api/mobile/dispatch', queryParameters: {
      'companyId': companyId,
      'guardId': guardId,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    });

    final data = res.data;

    if (data is Map && data['dispatchList'] is List) {
      return (data['dispatchList'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected dispatch response: $data');
  }


  // ACCEPTING DISPATCH
  Future<Map<String, dynamic>> acceptDispatch({
    required String dispatchId,
  }) async {
    final guardId = (SessionData.userProfile?['_id'] ?? '').toString();

    final res = await _dio.post('/api/dispatch/accept/$dispatchId', data: {
      'guardId': guardId,
    });

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected accept dispatch response: ${res.data}');
  }


//   VISITORS
  Future<Map<String, dynamic>> getVisitorCloudinarySign({
    required String visitorTempId,
    required String kind,
  }) async {
    final res = await _dio.post('/uploads/cloudinary-sign', data: {
      'moduleType': 'visitor',
      'visitorTempId': visitorTempId,
      'kind': kind,
    });

    if (res.data is Map) return Map<String, dynamic>.from(res.data);
    throw Exception('Unexpected visitor cloudinary sign response: ${res.data}');
  }

  Future<List<Map<String, dynamic>>> listVisitors({
    required String companyId,
    required String postSiteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _dio.get('/api/visitors', queryParameters: {
      'companyId': companyId,
      'postSiteId': postSiteId,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    });

    final data = res.data;

    if (data is Map && data['visitors'] is List) {
      return (data['visitors'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected visitors response: $data');
  }

  Future<Map<String, dynamic>> createVisitor(Map<String, dynamic> payload) async {
    final res = await _dio.post('/api/visitors/create', data: payload);

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected create visitor response: ${res.data}');
  }

  Future<List<Map<String, dynamic>>> listGuardChecklists({
    required String companyId,
    required String postSiteId,
    required String guardId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _dio.get('/api/checklists', queryParameters: {
      'companyId': companyId,
      'postSiteId': postSiteId,
      'guardId': guardId,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    });

    final data = res.data;

    if (data is Map && data['checklists'] is List) {
      return (data['checklists'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected checklist response: $data');
  }

  // Check List API

  Future<Map<String, dynamic>> checkChecklistItem({
    required String checklistId,
    required String guardId,
    required int itemIndex,
    required bool checked,
  }) async {
    final res = await _dio.post('/api/checklists/$checklistId/check-item', data: {
      'guardId': guardId,
      'itemIndex': itemIndex,
      'checked': checked,
    });

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected checklist item response: ${res.data}');
  }

  Future<Map<String, dynamic>> completeChecklist({
    required String checklistId,
    required String guardId,
  }) async {
    final res = await _dio.post('/api/checklists/$checklistId/complete', data: {
      'guardId': guardId,
    });

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected complete checklist response: ${res.data}');
  }





  Future<Map<String, dynamic>> listNotifications({
    required String companyId,
    required String viewerId,
  }) async {
    final res = await _dio.get('/api/notifications', queryParameters: {
      'companyId': companyId,
      'viewerId': viewerId,
    });

    if (res.data is Map) return Map<String, dynamic>.from(res.data);
    throw Exception('Unexpected notifications response: ${res.data}');
  }

  Future<void> clearNotifications({
    required String companyId,
    required String viewerId,
  }) async {
    await _dio.post('/api/notifications/clear', data: {
      'companyId': companyId,
      'viewerId': viewerId,
    });
  }

//   Shifts
  Future<List<Map<String, dynamic>>> listOpenShifts({
    required String companyId,
    required String guardId,
    String? postSiteId,
  }) async {
    final res = await _dio.get('/api/mobile/open-shifts', queryParameters: {
      'companyId': companyId,
      'guardId': guardId,
      if (postSiteId != null) 'postSiteId': postSiteId,
    });

    final data = res.data;

    if (data is Map && data['shifts'] is List) {
      return (data['shifts'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected open shifts response: $data');
  }

  Future<Map<String, dynamic>> selectOpenShift({
    required String shiftTemplateId,
    required String guardId,
    required String guardName,
  }) async {
    final res = await _dio.post('/api/mobile/open-shifts/select', data: {
      'shiftTemplateId': shiftTemplateId,
      'guardId': guardId,
      'guardName': guardName,
    });

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected select shift response: ${res.data}');
  }


//   EXCGANGE SHIFT
  Future<Map<String, dynamic>> sendShiftExchangeRequest({
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.post('/api/mobile/shift-exchange/request', data: payload);

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected shift exchange request response');
  }

  Future<List<Map<String, dynamic>>> getReceivedShiftExchangeRequests({
    required String companyId,
    required String guardId,
    String? shiftTemplateId,
  }) async {
    final res = await _dio.get('/api/mobile/shift-exchange/received', queryParameters: {
      'companyId': companyId,
      'guardId': guardId,
      if (shiftTemplateId != null) 'shiftTemplateId': shiftTemplateId,
    });

    final data = res.data;

    if (data is Map && data['exchanges'] is List) {
      return (data['exchanges'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected shift exchange response');
  }

  Future<Map<String, dynamic>> respondShiftExchange({
    required String exchangeId,
    required String status,
  }) async {
    final res = await _dio.post('/api/mobile/shift-exchange/respond', data: {
      'exchangeId': exchangeId,
      'status': status,
    });

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected shift exchange respond response');
  }

  Future<List<Map<String, dynamic>>> getShiftExchangeGuards({
    required String companyId,
    required String postSiteId,
    required String guardId,
  }) async {
    final res = await _dio.get('/api/mobile/shift-exchange/guards', queryParameters: {
      'companyId': companyId,
      'postSiteId': postSiteId,
      'guardId': guardId,
    });

    final data = res.data;

    if (data is Map && data['guards'] is List) {
      return (data['guards'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected guards response');
  }


//   time off
  Future<List<Map<String, dynamic>>> getMyTimeOffRequests({
    required String companyId,
    required String guardId,
  }) async {
    final res = await _dio.get('/api/mobile/time-off/my-requests', queryParameters: {
      'companyId': companyId,
      'guardId': guardId,
    });

    final data = res.data;

    if (data is Map && data['requests'] is List) {
      return (data['requests'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected time off response');
  }

  Future<Map<String, dynamic>> submitTimeOffRequest({
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.post('/api/mobile/time-off/request', data: payload);

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected time off request response');
  }

  Future<List<Map<String, dynamic>>> getMySchedule({
    required String companyId,
    required String guardId,
  }) async {
    final res = await _dio.get('/api/mobile/my-schedule', queryParameters: {
      'companyId': companyId,
      'guardId': guardId,
    });

    final data = res.data;

    if (data is Map && data['shifts'] is List) {
      return (data['shifts'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected schedule response: $data');
  }

//   Tasks
  Future<List<Map<String, dynamic>>> listPostSiteTasks({
    required String companyId,
    required String guardId,
    String? postSiteId,
    DateTime? date,
  }) async {
    final res = await _dio.get('/api/post-site-tasks', queryParameters: {
      'companyId': companyId,
      'guardId': guardId,
      if (postSiteId != null) 'postSiteId': postSiteId,
      if (date != null)
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
    });

    final data = res.data;

    if (data is Map && data['tasks'] is List) {
      return (data['tasks'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    throw Exception('Unexpected task response: $data');
  }

  Future<Map<String, dynamic>> completePostSiteTask({
    required String taskId,
    required String guardId,
    required String completedDate,
    required List<int> completedSubTasks,
  }) async {
    final res = await _dio.post('/api/post-site-tasks/$taskId/complete', data: {
      'guardId': guardId,
      'completedDate': completedDate,
      'completedSubTasks': completedSubTasks,
    });

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected complete task response: ${res.data}');
  }

  Future<Map<String, dynamic>> getWatchModeCloudinarySign({
    required String watchModeTempId,
    required String kind,
  }) async {
    final res = await _dio.post('/uploads/cloudinary-sign', data: {
      'moduleType': 'watchmode',
      'watchModeTempId': watchModeTempId,
      'kind': kind,
    });

    if (res.data is Map) return Map<String, dynamic>.from(res.data);
    throw Exception('Unexpected watchmode cloudinary sign response: ${res.data}');
  }


  Future<Map<String, dynamic>> createWatchMode({
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.post('/api/watchmode/create', data: payload);

    if (res.data is Map) return Map<String, dynamic>.from(res.data);
    throw Exception('Unexpected createWatchMode response: ${res.data}');
  }

  Future<Map<String, dynamic>> getDAR({
    required String companyId,
    required String date,
    String postSiteId = 'all',
  }) async {
    final res = await _dio.get(
      '/api/dar',
      queryParameters: {
        'companyId': companyId,
        'date': date,
        'postSiteId': postSiteId,
      },
    );

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Unexpected DAR response');
  }

  Future<void> resendCodeRedReportEmail(
      String reportId,
      ) async {
    try {
      final response = await _dio.post(
        '/reports/$reportId/resend-code-red-email',
      );

      final data = response.data;

      if (data is Map && data['ok'] != true) {
        throw Exception(
          data['error']?.toString() ??
              'Unable to resend Code Red email',
        );
      }
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      throw Exception(
        'Unable to resend Code Red email',
      );
    }
  }

  Future<Map<String, dynamic>> guardPhoneSignIn({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/guard-phone-signin',
        data: {
          'phone': phone.trim(),
          'password': password,
        },
      );

      return Map<String, dynamic>.from(
        response.data as Map,
      );
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception(
        'Unable to sign in. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>>
  selectGuardPhoneLoginAccount({
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '/guard-phone-signin/select-account',
        data: {
          'userId': userId,
        },
      );

      return Map<String, dynamic>.from(
        response.data as Map,
      );
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception(
        'Unable to select the guard account.',
      );
    }
  }






}