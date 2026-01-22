import 'package:flutter/material.dart';
import 'audio_player_tile.dart';
import 'video_player_tile.dart';

class ReportAttachmentCard extends StatelessWidget {
  final Map<String, dynamic> attachment;
  const ReportAttachmentCard({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    final url = (attachment['secureUrl'] ?? '').toString().trim();
    if (url.isEmpty) return const SizedBox.shrink();

    final kind = _inferKind(url, attachment['kind']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2F35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),

          if (kind == 'video')
            VideoPlayerTile(url: url)
          else if (kind == 'audio')
            AudioPlayerTile(url: url)
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(url, fit: BoxFit.cover),
            ),
        ],
      ),
    );
  }

  String _inferKind(String url, dynamic rawKind) {
    final k = (rawKind ?? '').toString().toLowerCase().trim();
    if (k == 'video' || k == 'audio' || k == 'image' || k == 'signature') return k;

    final u = url.toLowerCase();

    // ✅ audio FIRST (cloudinary audio can live under /video/upload/)
    if (u.endsWith('.mp3') || u.endsWith('.m4a') || u.endsWith('.aac') || u.endsWith('.wav')) {
      return 'audio';
    }

    if (u.contains('/video/upload/') || u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.mkv')) {
      return 'video';
    }

    return 'image';
  }

}
