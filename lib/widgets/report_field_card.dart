import 'package:flutter/material.dart';
import 'package:watch_team/widgets/audio_player_tile.dart';
import 'package:watch_team/widgets/network_video_player.dart';

class ReportFieldCard extends StatelessWidget {
  final String label;
  final String value;

  const ReportFieldCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          // ✅ If it’s a cloudinary URL, render media instead of Text
          _renderValue(v),
        ],
      ),
    );
  }

  Widget _renderValue(String v) {
    if (!_looksLikeUrl(v)) {
      return Text(v, style: const TextStyle(color: Colors.white));
    }

    final lower = v.toLowerCase();

    // ✅ VIDEO
    if (lower.contains('res.cloudinary.com') &&
        (lower.contains('/video/upload/') ||
            lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.mkv'))) {
      return NetworkVideoPlayer(url: v);
    }

    // ✅ AUDIO (cloudinary audio is usually under /video/upload too)
    if (lower.contains('res.cloudinary.com') &&
        (lower.endsWith('.mp3') ||
            lower.endsWith('.m4a') ||
            lower.endsWith('.aac') ||
            lower.endsWith('.wav'))) {
      return AudioPlayerTile(url: v);
    }

    // ✅ IMAGE/SIGNATURE
    if (lower.contains('res.cloudinary.com') &&
        (lower.contains('/image/upload/') ||
            lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(v, fit: BoxFit.cover),
      );
    }

    // ✅ Unknown URL: show clickable but not ugly big link
    return _UrlChip(url: v);
  }

  bool _looksLikeUrl(String s) {
    final u = s.toLowerCase();
    return u.startsWith('http://') || u.startsWith('https://');
  }
}

class _UrlChip extends StatelessWidget {
  final String url;
  const _UrlChip({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Open media link',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
