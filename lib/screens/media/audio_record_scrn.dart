import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordScreen extends StatefulWidget {
  const AudioRecordScreen({super.key, this.maxSeconds = 60});
  final int maxSeconds;

  @override
  State<AudioRecordScreen> createState() => _AudioRecordScreenState();
}

class _AudioRecordScreenState extends State<AudioRecordScreen> {
  final AudioRecorder _rec = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;

  @override
  void dispose() {
    _timer?.cancel();
    _rec.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await _rec.hasPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _recording = true;
      _seconds = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _seconds++);
      if (_seconds >= widget.maxSeconds) {
        await _stopAndReturn();
      }
    });
  }

  Future<void> _stopAndReturn() async {
    _timer?.cancel();
    final p = await _rec.stop();
    setState(() => _recording = false);

    if (p == null) return;
    if (!mounted) return;
    Navigator.pop(context, File(p));
  }

  String _fmt(int s) {
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        title: const Text('Audio Record'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Maximum time : ${widget.maxSeconds} seconds',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 18),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2B2F35), width: 6),
              ),
              child: Center(
                child: Text(
                  _fmt(_seconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _recording ? 'Recording...' : 'Tap the button to start recording',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 18),
            FloatingActionButton(
              backgroundColor: const Color(0xFFFF5A3D),
              onPressed: _recording ? _stopAndReturn : _start,
              child: Icon(_recording ? Icons.stop : Icons.mic, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
