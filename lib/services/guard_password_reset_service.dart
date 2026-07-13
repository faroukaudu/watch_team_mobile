import 'package:dio/dio.dart';

class GuardPasswordResetService {
  final Dio _dio;

  GuardPasswordResetService({
    required String baseUrl,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  Future<Map<String, dynamic>> requestOtp({
    required String email,
    String? userId,
  }) async {
    return _post(
      '/guard-password-reset/request',
      {
        'email': email.trim(),
        if (userId != null && userId.isNotEmpty)
          'userId': userId,
      },
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String otp,
  }) async {
    return _post(
      '/guard-password-reset/verify',
      {
        'userId': userId,
        'otp': otp,
      },
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async {
    return _post(
      '/guard-password-reset/complete',
      {
        'userId': userId,
        'resetToken': resetToken,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(
          response.data as Map,
        );
      }

      throw Exception('Invalid response from server.');
    } on DioException catch (error) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        final message =
            responseData['message']?.toString();

        if (message != null && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception(
        'Unable to connect to the server. Please try again.',
      );
    }
  }
}
