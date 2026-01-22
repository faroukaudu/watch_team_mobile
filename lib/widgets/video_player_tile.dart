import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerTile extends StatefulWidget {
  final String url;
  const VideoPlayerTile({super.key, required this.url});

  @override
  State<VideoPlayerTile> createState() => _VideoPlayerTileState();
}

class _VideoPlayerTileState extends State<VideoPlayerTile> {
  VideoPlayerController? _vc;
  ChewieController? _cc;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _vc = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _vc!.addListener(() {
        final v = _vc!.value;
        if (v.hasError) {
          debugPrint('❌ VIDEO PLAYER ERROR: ${v.errorDescription}');
        }
      });
      await _vc!.initialize();
      // if (_vc!.value.hasError) {
      //   print("IAM HERE!!!");
      //   final err = _vc!.value.errorDescription;
      //   throw Exception(err ?? 'Unknown video error');
      // }

      _cc = ChewieController(
        videoPlayerController: _vc!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Video failed: $e')));
    }
  }

  @override
  void dispose() {
    _cc?.dispose();
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cc == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2F35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator()),
            SizedBox(width: 12),
            Text('Loading video...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _vc?.value.aspectRatio ?? (16 / 9),
        child: Chewie(controller: _cc!),
      ),
    );
  }
}
