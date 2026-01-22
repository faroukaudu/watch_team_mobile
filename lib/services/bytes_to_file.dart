import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<File> bytesToTempPng(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
  return file.writeAsBytes(bytes, flush: true);
}
