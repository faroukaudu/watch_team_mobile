import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MediaCaptureService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> captureImageFromCamera() async {
    final XFile? x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    return x == null ? null : File(x.path);
  }

  Future<File?> captureVideoFromCamera() async {
    final XFile? x = await _picker.pickVideo(source: ImageSource.camera);
    return x == null ? null : File(x.path);
  }
}
