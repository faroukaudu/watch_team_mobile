import 'dart:io';
import 'package:file_picker/file_picker.dart';

class AudioPickerService {
  Future<File?> pickAudioFromFiles() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'wav', 'aac'],
    );
    if (res == null || res.files.isEmpty) return null;
    final path = res.files.single.path;
    if (path == null) return null;
    return File(path);
  }
}
