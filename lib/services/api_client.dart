import 'package:dio/dio.dart';
import 'package:watch_team/session_data.dart';

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
}