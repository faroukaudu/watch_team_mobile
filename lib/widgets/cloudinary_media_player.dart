import 'package:audio_session/audio_session.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

class CloudinaryMediaPlayer extends StatelessWidget {
  final String url;
  const CloudinaryMediaPlayer({super.key, required this.url});

  bool get _isVideo {
    final u = url.toLowerCase();
    return u.contains('/video/upload/') || u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.mkv');
  }

  bool get _isAudio {
    final u = url.toLowerCase();
    return u.endsWith('.mp3') || u.endsWith('.m4a') || u.endsWith('.aac') || u.endsWith('.wav');
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) return _VideoBox(url: url);
    if (_isAudio) return _AudioBox(url: url);

    // fallback: if unknown, just show link
    return Text(url, style: const TextStyle(color: Colors.white70));
  }
}

class _VideoBox extends StatefulWidget {
  final String url;
  const _VideoBox({required this.url});

  @override
  State<_VideoBox> createState() => _VideoBoxState();
}

class _VideoBoxState extends State<_VideoBox> {
  VideoPlayerController? _vc;
  ChewieController? _cc;
  String? _err;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final uri = Uri.parse(widget.url);
      _vc = VideoPlayerController.networkUrl(uri);
      await _vc!.initialize();

      if (_vc!.value.hasError) {
        setState(() => _err = _vc!.value.errorDescription ?? 'Video error');
        return;
      }

      _cc = ChewieController(
        videoPlayerController: _vc!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
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
    if (_err != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2F35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Text('Video failed: $_err', style: const TextStyle(color: Colors.white70)),
      );
    }

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
      child: Chewie(controller: _cc!),
    );
  }
}

class _AudioBox extends StatefulWidget {
  final String url;
  const _AudioBox({required this.url});

  @override
  State<_AudioBox> createState() => _AudioBoxState();
}

class _AudioBoxState extends State<_AudioBox> {
  final _player = AudioPlayer();
  bool _ready = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      await _player.setUrl(widget.url);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_err != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2F35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Text('Audio failed: $_err', style: const TextStyle(color: Colors.white70)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2F35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snap) {
              final playing = snap.data?.playing ?? false;

              if (!_ready) {
                return const SizedBox(width: 40, height: 40, child: CircularProgressIndicator());
              }

              return IconButton(
                icon: Icon(playing ? Icons.pause_circle : Icons.play_circle, color: Colors.white),
                iconSize: 40,
                onPressed: () => playing ? _player.pause() : _player.play(),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, durSnap) {
                final total = durSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;

                    final double maxMs = (total.inMilliseconds <= 0)
                        ? 1.0
                        : total.inMilliseconds.toDouble();
                    final double curMs = pos.inMilliseconds.toDouble().clamp(0.0, maxMs);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: curMs,
                          min: 0.0,
                          max: maxMs,
                          onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                        ),
                        Text(
                          '${_fmt(pos)} / ${_fmt(total)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$m:$s';
  }
}
