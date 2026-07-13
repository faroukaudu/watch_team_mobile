import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/services/cloudinary_uploader.dart';
import 'package:watch_team/services/media_capture_service.dart';

class WatchModeScreen extends StatefulWidget {
  const WatchModeScreen({super.key});

  @override
  State<WatchModeScreen> createState() => _WatchModeScreenState();
}

class _WatchModeScreenState extends State<WatchModeScreen> {
  final TextEditingController noteController = TextEditingController();
  final MediaCaptureService media = MediaCaptureService();

  File? selectedVideo;
  VideoPlayerController? previewController;

  bool submitting = false;
  bool loadingPrevious = false;

  List<Map<String, dynamic>> previousVideos = [];

  String get companyId {
    return (SessionData.companyInfo?['_id'] ??
        SessionData.userProfile?['assignedCompanyID'] ??
        '')
        .toString();
  }

  String get guardId {
    return (SessionData.userProfile?['_id'] ??
        SessionData.userProfile?['id'] ??
        g.currentUserId ??
        '')
        .toString();
  }

  String get guardName {
    final user = SessionData.userProfile ?? {};

    final firstName = (user['firstName'] ?? '').toString();
    final lastName = (user['lastName'] ?? '').toString();

    final fullName = '$firstName $lastName'.trim();

    return (user['fullName'] ??
        user['name'] ??
        (fullName.isNotEmpty ? fullName : null) ??
        'Guard')
        .toString();
  }

  @override
  void initState() {
    super.initState();
    loadPreviousVideos();
  }

  Future<void> setupPreview(File videoFile) async {
    await previewController?.dispose();

    previewController = VideoPlayerController.file(videoFile);
    await previewController!.initialize();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> recordVideo() async {
    final file = await media.captureVideoFromCamera();

    if (file == null) return;

    setState(() {
      selectedVideo = file;
    });

    await setupPreview(file);
  }

  Future<void> submitWatchMode() async {
    if (selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a video first.')),
      );
      return;
    }

    if (companyId.isEmpty || guardId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing company or guard profile.')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      // 1. SERVICES — place service/helper/API setup immediately after try {
      final dio = Dio();
      final api = ApiClient(baseUrl: g.baseUrl);
      final cloudinary = CloudinaryUploader(dio);

      // 2. TEMP ID — used to create a unique Cloudinary folder
      final watchModeTempId = DateTime.now().millisecondsSinceEpoch.toString();

      // 3. SIGNATURE — your existing Cloudinary signing flow
      final sign = await api.getWatchModeCloudinarySign(
        watchModeTempId: watchModeTempId,
        kind: 'video',
      );

      // 4. UPLOAD — upload selected video to Cloudinary
      final cloud = await cloudinary.upload(
        sign: sign,
        file: selectedVideo!,
      );

      // 5. BACKEND SAVE — save Cloudinary video details to MongoDB/backend
      final response = await api.createWatchMode(
        payload: {
          'companyId': companyId,
          'guardId': guardId,
          'guardName': guardName,
          'videoUrl': cloud['secure_url'] ?? cloud['url'],
          'publicId': cloud['public_id'],
          'duration': cloud['duration'],
          'resourceType': cloud['resource_type'],
          'format': cloud['format'],
          'bytes': cloud['bytes'],
          'note': noteController.text.trim(),
        },
      );

      if (response['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WatchMode video submitted successfully.'),
          ),
        );

        await previewController?.dispose();
        previewController = null;

        setState(() {
          selectedVideo = null;
          noteController.clear();
        });

        await loadPreviousVideos();
      } else {
        throw Exception(response['message'] ?? 'Submission failed.');
      }
    } on DioException catch (e) {
      debugPrint('DIO ERROR URL: ${e.requestOptions.uri}');
      debugPrint('DIO ERROR STATUS: ${e.response?.statusCode}');
      debugPrint('DIO ERROR DATA: ${e.response?.data}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit WatchMode video: ${e.response?.data ?? e.message}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('WatchMode submit error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit WatchMode video: $e')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> loadPreviousVideos() async {
    if (companyId.isEmpty || guardId.isEmpty) return;

    setState(() => loadingPrevious = true);

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: g.baseUrl,
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await dio.get(
        '/api/watchmode/my-videos',
        queryParameters: {
          'companyId': companyId,
          'guardId': guardId,
        },
      );

      final data = response.data;

      List items = [];

      if (data is Map && data['watchModes'] is List) {
        items = data['watchModes'];
      } else if (data is Map && data['videos'] is List) {
        items = data['videos'];
      } else if (data is List) {
        items = data;
      }

      setState(() {
        previousVideos = items.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      debugPrint('Load previous WatchMode videos error: $e');
    } finally {
      if (mounted) setState(() => loadingPrevious = false);
    }
  }

  String cloudinaryThumbnail(String videoUrl) {
    if (!videoUrl.contains('/video/upload/')) return videoUrl;

    return videoUrl
        .replaceFirst('/video/upload/', '/video/upload/so_0,w_500,h_300,c_fill/')
        .replaceAll(RegExp(r'\.(mp4|mov|m4v|webm)$'), '.jpg');
  }

  String formatDate(dynamic value) {
    if (value == null) return 'N/A';

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  void openVideoPlayer(Map<String, dynamic> item) {
    final videoUrl = (item['videoUrl'] ?? '').toString();

    if (videoUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: WatchModeNetworkVideoModal(
            videoUrl: videoUrl,
            note: (item['note'] ?? '').toString(),
            date: formatDate(item['createdAt']),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    previewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = selectedVideo != null;
    final previewReady =
        previewController != null && previewController!.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        elevation: 0,
        title: const Text(
          'Watch Mode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: loadPreviousVideos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroCard(),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Live Video Feed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Record and submit a WatchMode video without checking in to any post site.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (previewReady)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: previewController!.value.aspectRatio,
                              child: VideoPlayer(previewController!),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  previewController!.value.isPlaying
                                      ? previewController!.pause()
                                      : previewController!.play();
                                });
                              },
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.black.withOpacity(0.55),
                                child: Icon(
                                  previewController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 190,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF243044)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasVideo ? Icons.video_file : Icons.videocam,
                              size: 58,
                              color: hasVideo
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white38,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              hasVideo
                                  ? 'Video selected'
                                  : 'No video recorded yet',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Note / Description',
                        labelStyle: const TextStyle(color: Colors.white60),
                        hintText: 'Example: suspicious activity near gate...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                          const BorderSide(color: Color(0xFF243044)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                          const BorderSide(color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: submitting ? null : recordVideo,
                            icon: const Icon(Icons.videocam),
                            label: Text(hasVideo ? 'Record Again' : 'Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: submitting ? null : submitWatchMode,
                            icon: submitting
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.cloud_upload),
                            label: Text(
                              submitting ? 'Submitting' : 'Submit',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Previously Uploaded Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: loadPreviousVideos,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (loadingPrevious)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (previousVideos.isEmpty)
                _emptyPrevious()
              else
                Column(
                  children: previousVideos.map((item) {
                    final videoUrl = (item['videoUrl'] ?? '').toString();
                    final thumb = cloudinaryThumbnail(videoUrl);

                    return GestureDetector(
                      onTap: () => openVideoPlayer(item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.network(
                                    thumb,
                                    height: 95,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        height: 95,
                                        width: 120,
                                        color: const Color(0xFF111827),
                                        child: const Icon(
                                          Icons.video_library,
                                          color: Colors.white38,
                                          size: 35,
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatDate(item['createdAt']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (item['note'] ?? 'No note added')
                                          .toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tap to view',
                                      style: TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF123458),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFF1E293B)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF0284C7),
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency WatchMode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Capture video evidence anytime without post-site check-in.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPrevious() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.video_collection_outlined,
            color: Colors.white38,
            size: 46,
          ),
          SizedBox(height: 10),
          Text(
            'No videos uploaded yet',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your submitted WatchMode videos will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class WatchModeNetworkVideoModal extends StatefulWidget {
  final String videoUrl;
  final String note;
  final String date;

  const WatchModeNetworkVideoModal({
    super.key,
    required this.videoUrl,
    required this.note,
    required this.date,
  });

  @override
  State<WatchModeNetworkVideoModal> createState() =>
      _WatchModeNetworkVideoModalState();
}

class _WatchModeNetworkVideoModalState
    extends State<WatchModeNetworkVideoModal> {
  late VideoPlayerController controller;
  bool ready = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => ready = true);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'WatchMode Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!ready)
            Container(
              height: 220,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.white),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        controller.value.isPlaying
                            ? controller.pause()
                            : controller.play();
                      });
                    },
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.black.withOpacity(0.55),
                      child: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.date,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.note.isEmpty ? 'No note added.' : widget.note,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}