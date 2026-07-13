
import 'package:dio/dio.dart';

class SupportService {
  final Dio _dio;
  final String userId;

  SupportService({
    required String baseUrl,
    required this.userId,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ));

  Options get _options => Options(headers: {'x-user-id': userId});

  Future<List<Map<String, dynamic>>> getSupportAdmins() async {
    final response = await _dio.get('/api/support/admins', options: _options);
    final raw = response.data is Map ? response.data['admins'] : null;
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<String> openChat(String otherUserId) async {
    final response = await _dio.post(
      '/api/chats/direct',
      data: {'otherUserId': otherUserId},
      options: _options,
    );
    return response.data['chatId'].toString();
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final response = await _dio.get(
      '/api/messages',
      queryParameters: {'chatId': chatId, 'limit': 100},
      options: _options,
    );
    if (response.data is! List) return [];
    final list = (response.data as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    list.sort((a, b) =>
        (a['createdAt'] ?? '').toString().compareTo((b['createdAt'] ?? '').toString()));
    return list;
  }

  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String body,
  }) async {
    await _dio.post(
      '/api/support/messages',
      data: {
        'chatId': chatId,
        'receiverId': receiverId,
        'body': body.trim(),
      },
      options: _options,
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post(
        '/api/guard/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        options: _options,
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      rethrow;
    }
  }
}
