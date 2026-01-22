import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../models/attachment.dart';
import '../services/api_client.dart';
import '../services/cloudinary_uploader.dart';
import '../services/bytes_to_file.dart';

Future<void> submitReport({
  required ApiClient api,
  required String reportTitle,
  required Map<String, dynamic> values,
  required Map<String, dynamic> controllersToValues, // if you already merged, ignore this
  required List<Attachment> attachments,
  Uint8List? signatureBytes, // pass values['signature'] as Uint8List?
  required void Function(double progress) onProgress,
}) async {
  // 1) Create report first (Mongo)
  final reportId = await api.createReport(title: reportTitle, fields: values);

  final cloudUploader = CloudinaryUploader(Dio());

  int totalUploads = attachments.length + (signatureBytes != null ? 1 : 0);
  int done = 0;

  Future<void> uploadOne({
    required String kind,
    required File file,
  }) async {
    final sign = await api.getCloudinarySign(reportId: reportId, kind: kind);
    final cloud = await cloudUploader.upload(sign: sign, file: file);

    // 2) Save ref to Mongo
    await api.saveAttachmentRef(
      reportId: reportId,
      payload: {
        'kind': kind,
        'publicId': cloud['public_id'],
        'secureUrl': cloud['secure_url'],
        'resourceType': cloud['resource_type'],
        'format': cloud['format'],
        'bytes': cloud['bytes'],
        'duration': cloud['duration'], // present for audio/video
      },
    );

    done++;
    onProgress(totalUploads == 0 ? 1 : done / totalUploads);
  }

  // 3) Upload signature (if present)
  if (signatureBytes != null) {
    final sigFile = await bytesToTempPng(signatureBytes);
    await uploadOne(kind: 'signature', file: sigFile);
  }

  // 4) Upload media attachments
  for (final a in attachments) {
    final kind = a.type.name; // image/video/audio/signature
    await uploadOne(kind: kind, file: a.file);
  }
}
