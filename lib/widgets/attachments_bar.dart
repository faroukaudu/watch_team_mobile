import 'package:flutter/material.dart';
import '../models/attachment.dart';

class AttachmentsBar extends StatelessWidget {
  final List<Attachment> items;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const AttachmentsBar({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text('Attachments',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _AttachmentTile(
                    attachment: items[i],
                    onRemove: () => onRemove(i),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // FloatingActionButton(
            //   heroTag: 'add_attach',
            //   mini: true,
            //   backgroundColor: const Color(0xFFFF5A3D),
            //   onPressed: onAdd,
            //   child: const Icon(Icons.add, color: Colors.white),
            // )
          ],
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentTile({required this.attachment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    Widget preview;

    switch (attachment.type) {
      case AttachmentType.image:
      case AttachmentType.signature:
        preview = Image.file(attachment.file, fit: BoxFit.cover);
        break;
      case AttachmentType.video:
        preview = const Center(
          child: Icon(Icons.videocam, color: Colors.white70, size: 34),
        );
        break;
      case AttachmentType.audio:
        preview = const Center(
          child: Icon(Icons.music_note, color: Colors.white70, size: 34),
        );
        break;
    }

    return Stack(
      children: [
        Container(
          width: 92,
          height: 82,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2F35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: preview,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5A3D),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
