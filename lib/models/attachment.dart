import 'dart:io';

enum AttachmentType { image, video, audio, signature }

class Attachment {
  final AttachmentType type;
  final File file;

  Attachment({required this.type, required this.file});
}
