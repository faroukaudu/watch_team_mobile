import 'dart:io';
import 'package:dio/dio.dart';

class CloudinaryUploader {
  CloudinaryUploader(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> upload({
    required Map<String, dynamic> sign, // from Node
    required File file,
  }) async {
    final cloudName = sign['cloudName'] as String;
    final apiKey = sign['apiKey'] as String;
    final timestamp = sign['timestamp'] as int;
    final signature = sign['signature'] as String;
    final folder = sign['folder'] as String;
    final resourceType = sign['resourceType'] as String; // image/video

    final cloudUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
      'folder': folder,
    });

    final resp = await _dio.post(cloudUrl, data: formData);
    return Map<String, dynamic>.from(resp.data);
  }
}
