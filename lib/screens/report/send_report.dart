import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:watch_team/session_data.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/attachment.dart';
import '../../services/api_client.dart';
import '../../services/cloudinary_uploader.dart';
import '../../services/bytes_to_file.dart';

import '../../widgets/attachments_bar.dart';
import '../../widgets/media_option_sheet.dart';
import '../../services/media_capture_service.dart';
import '../../services/gallery_picker_ser.dart';
import '../../services/audio_rec_ser.dart';

import '../media/audio_record_scrn.dart';
import 'signature_screen.dart';
import 'package:watch_team/global.dart' as g;

enum FieldType { dropdown, date, text, textarea, radio, signature }

class FormFieldDef {
  final String keyName;
  final String label;
  final FieldType type;

  final bool aiBadge;
  final List<String>? options;
  final String? hint;
  final int maxLines;

  const FormFieldDef({
    required this.keyName,
    required this.label,
    required this.type,
    this.aiBadge = false,
    this.options,
    this.hint,
    this.maxLines = 1,
  });
}

class ReportFormSchema {
  final String title;
  final List<FormFieldDef> fields;
  final bool showFabMenu;

  const ReportFormSchema({
    required this.title,
    required this.fields,
    this.showFabMenu = true,
  });
}

/// --- SCHEMAS (keep yours, this is same pattern you already have) ---
/// (This is directly based on your uploaded code. :contentReference[oaicite:1]{index=1})
ReportFormSchema schemaForTitle(String reportTitle) {
  switch (reportTitle.trim().toLowerCase()) {
    case 'break-in':
      return const ReportFormSchema(
        title: 'Break-In',
        showFabMenu: true,
        fields: [
          FormFieldDef(
            keyName: 'incident_type',
            label: 'SELECT INCIDENTS',
            type: FieldType.dropdown,
            hint: 'Select Incident',
            options: ['Break-In', 'Theft', 'Vandalism', 'Suspicious Activity'],
          ),
          FormFieldDef(
            keyName: 'incident_date',
            label: 'DATE OF THE INCIDENT',
            type: FieldType.date,
          ),
          FormFieldDef(
            keyName: 'location',
            label: 'LOCATION',
            type: FieldType.textarea,
            hint: 'Location',
            maxLines: 4,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'police_called',
            label: 'WAS POLICE CALLED?',
            type: FieldType.radio,
            options: ['Yes', 'No'],
          ),
          FormFieldDef(
            keyName: 'witness',
            label: 'WAS THERE A WITNESS?',
            type: FieldType.radio,
            options: ['Yes', 'No'],
          ),
          FormFieldDef(
            keyName: 'witness_name',
            label: 'IF YES, NAME THE WITNESS',
            type: FieldType.textarea,
            hint: 'witness',
            maxLines: 2,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'item_stolen',
            label: 'LIST ANY ITEMS THAT WERE TAKEN ',
            type: FieldType.textarea,
            hint: 'Stolen Items',
            maxLines: 4,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'NARRATIVE',
            label: 'Narrative',
            type: FieldType.textarea,
            hint: 'Narrative',
            maxLines: 4,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'signature',
            label: 'SIGNATURE *',
            type: FieldType.signature,
          ),
        ],
      );
    case 'fire alarm':
    case 'fire-alarm':
    case 'fire alert':
    case 'fire alarm alert':
      return ReportFormSchema(
        title: reportTitle,
        showFabMenu: true,
        fields: [
          FormFieldDef(
            keyName: 'incident_type',
            label: 'SELECT INCIDENTS',
            type: FieldType.dropdown,
            hint: 'Select Incident',
            options: ['Break-In', 'Theft', 'Vandalism', 'Suspicious Activity'],
          ),
          FormFieldDef(
            keyName: 'incident_date',
            label: 'DATE OF THE INCIDENT',
            type: FieldType.date,
          ),
          FormFieldDef(
            keyName: 'location',
            label: 'LOCATION',
            type: FieldType.textarea,
            hint: 'Location',
            maxLines: 4,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'police_called',
            label: 'WAS POLICE CALLED?',
            type: FieldType.radio,
            options: ['Yes', 'No'],
          ),
          FormFieldDef(
            keyName: 'witness',
            label: 'WAS THERE A WITNESS?',
            type: FieldType.radio,
            options: ['Yes', 'No'],
          ),
          FormFieldDef(
            keyName: 'signature',
            label: 'SIGNATURE *',
            type: FieldType.signature,
          ),
        ],
      );

    case 'Detailed Incident Report':
    case 'detailed incident report':
    case 'Detailed-Incident-Report':
    case 'detailed-incident-report':
      return ReportFormSchema(
        title: reportTitle,
        showFabMenu: true,
        fields: [
          FormFieldDef(
            keyName: 'incident_type',
            label: 'SELECT INCIDENTS',
            type: FieldType.dropdown,
            hint: 'Select Incident',
            options: ['Abandon Vehicle', 'Accident', 'Arson',
              'Assult','Collision', 'Disturbance', 'EMT Onsite', 'Injury','Item Lost',
              'Maintenance','Parking Violation', 'Police Onsite','Robbery','Threat','Theft',
            'Trespassing','Vandalism','Violation','Weather'],
          ),
          FormFieldDef(
            keyName: 'incident_date',
            label: 'DATE OF THE INCIDENT',
            type: FieldType.date,
          ),
          FormFieldDef(
            keyName: 'victims_names',
            label: 'VICTIMS NAME(S)',
            type: FieldType.textarea,
            hint: 'Victims Name',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'victims_contact',
            label: 'VICTIMS CONTACT',
            type: FieldType.textarea,
            hint: 'Victims Contact',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'suspect_names',
            label: 'SUSPECT NAME(S)',
            type: FieldType.textarea,
            hint: 'Suspect Names',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'suspect_contact',
            label: 'SUSPECT CONTACT',
            type: FieldType.textarea,
            hint: 'Suspect Contact',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'witness_names',
            label: 'WITNESS NAME(S)',
            type: FieldType.textarea,
            hint: 'Witness Name(s)',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'witness_contact',
            label: 'WITNESS CONTACT',
            type: FieldType.textarea,
            hint: 'Witness Contact',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'incident_location',
            label: 'INCIDENT LOCATION',
            type: FieldType.textarea,
            hint: 'Incident Location',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'incident_summary',
            label: 'INCIDENT SUMMARY',
            type: FieldType.textarea,
            hint: 'Incident Summary',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'police_called',
            label: 'WAS POLICE CALLED?',
            type: FieldType.radio,
            options: ['Yes', 'No'],
          ),
          FormFieldDef(
            keyName: 'why_no_police',
            label: 'IF NOT WHY?',
            type: FieldType.textarea,
            hint: 'if Not Why?',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'police_names',
            label: 'POLICE NAME(S)',
            type: FieldType.textarea,
            hint: 'police Name',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'action_taken',
            label: 'ACTION TAKEN',
            type: FieldType.textarea,
            hint: 'Action Taken',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'notes',
            label: 'NOTES',
            type: FieldType.textarea,
            hint: 'Notes',
            maxLines: 3,
            aiBadge: true,
          ),

          FormFieldDef(
            keyName: 'signature',
            label: 'SIGNATURE *',
            type: FieldType.signature,
          ),
        ],
      );

    case 'Equipment Inspection Report':
    case 'equipment inspection report':
    case 'Equipment-Inspection-Report':
    // case 'detailed-incident-report':
      return ReportFormSchema(
        title: reportTitle,
        showFabMenu: true,
        fields: [

          // FormFieldDef(
          //   keyName: 'report_date',
          //   label: 'DATE OF THE REPORT',
          //   type: FieldType.date,
          // ),

          FormFieldDef(
            keyName: 'equipment_type',
            label: 'EQUIPMENT TYPE',
            type: FieldType.textarea,
            hint: 'Equipment Type',
            maxLines: 4,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'reading',
            label: 'READING',
            type: FieldType.textarea,
            hint: 'reading',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'condition',
            label: 'CONDITION',
            type: FieldType.textarea,
            hint: 'Condition',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'notes',
            label: 'NOTES',
            type: FieldType.textarea,
            hint: 'Notes',
            maxLines: 3,
            aiBadge: true,
          ),

          FormFieldDef(
            keyName: 'signature',
            label: 'SIGNATURE *',
            type: FieldType.signature,
          ),
        ],
      );

    case 'Parking Violation':
    case 'parking violation':
    case 'Parking-Violation':
    // case 'detailed-incident-report':
      return ReportFormSchema(
        title: reportTitle,
        showFabMenu: true,
        fields: [

          // FormFieldDef(
          //   keyName: 'report_date',
          //   label: 'DATE OF THE REPORT',
          //   type: FieldType.date,
          // ),

          FormFieldDef(
            keyName: 'violator_name',
            label: 'VIOLATOR NAME',
            type: FieldType.textarea,
            hint: 'Violator Name',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'vehicle_make',
            label: 'VEHICLE MAKE',
            type: FieldType.textarea,
            hint: 'Vehicle Make',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'model',
            label: 'MODEL',
            type: FieldType.textarea,
            hint: 'Notes',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'lp',
            label: 'LP',
            type: FieldType.textarea,
            hint: 'lp',
            maxLines: 3,
            aiBadge: true,
          ),
          FormFieldDef(
            keyName: 'color',
            label: 'COLOR',
            type: FieldType.textarea,
            hint: 'color',
            maxLines: 3,
            aiBadge: true,
          ),

          FormFieldDef(
            keyName: 'signature',
            label: 'SIGNATURE *',
            type: FieldType.signature,
          ),
        ],
      );


    default:
      return ReportFormSchema(
        title: reportTitle,
        showFabMenu: true,
        fields: const [
          FormFieldDef(
            keyName: 'incident_date',
            label: 'DATE',
            type: FieldType.date,
          ),
          FormFieldDef(
            keyName: 'details',
            label: 'DETAILS',
            type: FieldType.textarea,
            hint: 'Enter details...',
            maxLines: 5,
          ),
          FormFieldDef(
            keyName: 'signature',
            label: 'SIGNATURE *',
            type: FieldType.signature,
          ),
        ],
      );
  }
}

class ReportFormScreen extends StatefulWidget {
  final String reportTitle;
  const ReportFormScreen({super.key, required this.reportTitle});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  // ==== CONFIG ====


  // IMPORTANT:
  // - If you're testing on a real phone, your base URL must be your PC LAN IP.
  // - If your Node app mounts routes under /api, set apiPrefix = '/api'.
  static final String baseUrl = '${g.baseUrl}';
  static const String apiPrefix = ''; // e.g. '/api'

  bool submitting = false;
  double uploadProgress = 0.0;

  late final ReportFormSchema schema;

  final Map<String, dynamic> values = {};
  final Map<String, TextEditingController> controllers = {};

  bool fabOpen = false;

  final mediaCapture = MediaCaptureService();
  final galleryPicker = GalleryPickerService();
  final audioPicker = AudioPickerService();

  final List<Attachment> attachments = [];

  Map<String, dynamic>? profile;
  @override
  void initState() {
    profile = SessionData.userProfile;
    super.initState();
    schema = schemaForTitle(widget.reportTitle);

    for (final f in schema.fields) {
      if (f.type == FieldType.date) {
        values[f.keyName] = DateTime.now();
      } else if (f.type == FieldType.text || f.type == FieldType.textarea) {
        controllers[f.keyName] = TextEditingController();
      } else {
        values[f.keyName] = null;
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Convert to JSON-safe (you already had this idea; keep it)
  Map<String, dynamic> makeJsonSafeMap(Map<String, dynamic> input) {
    dynamic convert(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.toIso8601String();
      if (v is Enum) return v.name;
      if (v is Duration) return v.inMilliseconds;

      if (v is Map) {
        return v.map((key, value) => MapEntry(key.toString(), convert(value)));
      }
      if (v is List) {
        return v.map(convert).toList();
      }

      if (v is String || v is num || v is bool) return v;

      // Never crash: stringify unknown values
      return v.toString();
    }

    return input.map((k, v) => MapEntry(k, convert(v)));
  }

  // =================== MEDIA PICKERS ===================

  Future<void> _openAttachmentChooser(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2B2F35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 12,
            children: [
              _attachAction(
                icon: Icons.image,
                text: 'Add Image(s)',
                onTap: () {
                  Navigator.pop(context);
                  _imageOptions(context);
                },
              ),
              _attachAction(
                icon: Icons.videocam,
                text: 'Add Video',
                onTap: () {
                  Navigator.pop(context);
                  _videoOptions(context);
                },
              ),
              _attachAction(
                icon: Icons.mic,
                text: 'Add Audio',
                onTap: () {
                  Navigator.pop(context);
                  _audioOptions(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachAction({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _imageOptions(BuildContext context) async {
    await showMediaOptionSheet(
      context: context,
      title: 'Image Option',
      subtitle: 'Select the option',
      leftText: 'Camera',
      rightText: 'Gallery',
      onLeft: () async {
        final f = await mediaCapture.captureImageFromCamera();
        if (f != null) {
          setState(() => attachments.add(Attachment(type: AttachmentType.image, file: f)));
        }
      },
      onRight: () async {
        final picked = await galleryPicker.pickImagesMax5(context);

        final currentImages = attachments.where((a) => a.type == AttachmentType.image).length;
        final remaining = 5 - currentImages;

        if (remaining <= 0) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 images allowed')),
          );
          return;
        }

        final toAdd = picked.take(remaining).toList();
        if (picked.length > remaining && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Only $remaining more image(s) allowed')),
          );
        }

        setState(() {
          attachments.addAll(toAdd.map((f) => Attachment(type: AttachmentType.image, file: f)));
        });
      },
    );
  }

  Future<void> _videoOptions(BuildContext context) async {
    await showMediaOptionSheet(
      context: context,
      title: 'Video Option',
      subtitle: 'Select the option',
      leftText: 'Camera',
      rightText: 'Gallery',
      onLeft: () async {
        final f = await mediaCapture.captureVideoFromCamera();
        if (f != null) {
          setState(() => attachments.add(Attachment(type: AttachmentType.video, file: f)));
        }
      },
      onRight: () async {
        final f = await galleryPicker.pickSingleVideo(context);
        if (f != null) {
          setState(() => attachments.add(Attachment(type: AttachmentType.video, file: f)));
        }
      },
    );
  }

  Future<void> _audioOptions(BuildContext context) async {
    await showMediaOptionSheet(
      context: context,
      title: 'Audio Option',
      subtitle: 'Select the option',
      leftText: 'Record',
      rightText: 'Files',
      onLeft: () async {
        // ✅ Fix: File is now known because we imported dart:io
        final file = await Navigator.push<File?>(
          context,
          MaterialPageRoute(builder: (_) => const AudioRecordScreen(maxSeconds: 60)),
        );
        if (file != null) {
          setState(() => attachments.add(Attachment(type: AttachmentType.audio, file: file)));
        }
      },
      onRight: () async {
        final f = await audioPicker.pickAudioFromFiles();
        if (f != null) {
          setState(() => attachments.add(Attachment(type: AttachmentType.audio, file: f)));
        }
      },
    );
  }

  // =================== SUBMIT ===================

  String _prettyDioError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final url = e.requestOptions.uri.toString();
      final data = e.response?.data;
      return 'HTTP $code\n$url\n$data';
    }
    return e.toString();
  }

  Future<void> _submit() async {
    if (submitting) return;

    // 1) collect text controllers
    for (final entry in controllers.entries) {
      values[entry.key] = entry.value.text.trim();
    }

    setState(() {
      submitting = true;
      uploadProgress = 0.0;
    });

    try {
      final api = ApiClient(
        baseUrl: baseUrl,
        apiPrefix: apiPrefix,
      );

      // Pull signature bytes OUT of fields JSON.
      final Uint8List? signatureBytes =
      values['signature'] is Uint8List ? values['signature'] as Uint8List : null;
      values['postSiteId'] = SessionData.postSiteID;

      final fieldsForMongo = Map<String, dynamic>.from(values);
      fieldsForMongo.remove('signature'); // ✅ do not JSON encode Uint8List

      final safeFields = makeJsonSafeMap(fieldsForMongo);

      // 2) Create report
      final reportId = await api.createReport(
        title: widget.reportTitle,
        fields: safeFields,
      );

      // 3) Upload to Cloudinary + store refs
      final cloudUploader = CloudinaryUploader(Dio());

      final totalUploads = attachments.length + (signatureBytes != null ? 1 : 0);
      int done = 0;

      Future<void> uploadOne({required String kind, required File file}) async {
        final sign = await api.getCloudinarySign(reportId: reportId, kind: kind);
        final cloud = await cloudUploader.upload(sign: sign, file: file);

        await api.saveAttachmentRef(
          reportId: reportId,
          payload: {
            'kind': kind,
            'publicId': cloud['public_id'],
            'secureUrl': cloud['secure_url'],
            'resourceType': cloud['resource_type'],
            'format': cloud['format'],
            'bytes': cloud['bytes'],
            'duration': cloud['duration'],
          },
        );

        done++;
        if (mounted) {
          setState(() {
            uploadProgress = totalUploads == 0 ? 1 : (done / totalUploads);
          });
        }
      }

      // Signature upload first (if present)
      if (signatureBytes != null) {
        final sigFile = await bytesToTempPng(signatureBytes);
        await uploadOne(kind: 'signature', file: sigFile);
      }

      // Other attachments
      for (final a in attachments) {
        await uploadOne(kind: a.type.name, file: a.file);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );

      setState(() {
        attachments.clear();
        for (final c in controllers.values) c.clear();
        values.clear();
        uploadProgress = 0.0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed:\n${_prettyDioError(e)}')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  // =================== FIELDS ===================

  Future<void> _pickDate(String keyName) async {
    final current = values[keyName] as DateTime? ?? DateTime.now();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0F3DFF),
              surface: Color(0xFF121212),
            ),
            dialogBackgroundColor: const Color(0xFF121212),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => values[keyName] = picked);
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final wd = weekdays[d.weekday - 1];
    final mm = months[d.month - 1];
    final dd = d.day.toString().padLeft(2, '0');
    return '$wd, $mm $dd, ${d.year}';
  }

  Widget _buildField(FormFieldDef f) {
    final labelRow = Row(
      children: [
        Expanded(child: _SectionLabel(f.label)),
        if (f.aiBadge) _AiBadge(),
      ],
    );

    switch (f.type) {
      case FieldType.signature:
        final Uint8List? sigBytes = values[f.keyName] as Uint8List?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelRow,
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                // ✅ MUST be Uint8List? because user may cancel/back
                final Uint8List? result = await Navigator.push<Uint8List?>(
                  context,
                  MaterialPageRoute(builder: (_) => const SignatureScreen()),
                );
                if (result != null) {
                  setState(() => values[f.keyName] = result);
                }
              },
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2F35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: sigBytes == null
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    const Icon(Icons.draw, color: Colors.white70),
                    const SizedBox(width: 10),
                    Text(
                      'Add Signature',
                      // textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                )
                    : Center(
                  child: SizedBox(
                    height: 40,
                    child: Image.memory(sigBytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        );

      case FieldType.dropdown:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelRow,
            const SizedBox(height: 10),
            _DarkDropdown(
              value: values[f.keyName] as String?,
              hint: f.hint ?? 'Select',
              items: f.options ?? const [],
              onChanged: (v) => setState(() => values[f.keyName] = v),
            ),
          ],
        );

      case FieldType.date:
        final dt = values[f.keyName] as DateTime? ?? DateTime.now();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelRow,
            const SizedBox(height: 10),
            _DarkTapField(
              text: _formatDate(dt),
              onTap: () => _pickDate(f.keyName),
              trailing: const Icon(Icons.calendar_month, color: Colors.white70),
            ),
          ],
        );

      case FieldType.text:
      case FieldType.textarea:
        final ctrl = controllers[f.keyName]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelRow,
            const SizedBox(height: 10),
            _DarkTextField(
              controller: ctrl,
              hint: f.hint ?? '',
              maxLines: f.maxLines,
            ),
          ],
        );

      case FieldType.radio:
        final current = values[f.keyName] as String?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelRow,
            const SizedBox(height: 10),
            ...((f.options ?? const []).map((opt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RadioCard(
                  title: opt,
                  selected: current == opt,
                  onTap: () => setState(() => values[f.keyName] = opt),
                ),
              );
            })),
          ],
        );
    }
  }

  // =================== UI ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text(
          schema.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      // ✅ Your FAB menu triggers mic/video/camera -> which open the camera/gallery/options
      floatingActionButton: schema.showFabMenu
          ? _FabMenu(
        isOpen: fabOpen,
        onToggle: () => setState(() => fabOpen = !fabOpen),
        onMic: () async {
          setState(() => fabOpen = false);
          await _audioOptions(context);
        },
        onVideo: () async {
          setState(() => fabOpen = false);
          await _videoOptions(context);
        },
        onCamera: () async {
          setState(() => fabOpen = false);
          await _imageOptions(context);
        },
      )
          : null,

      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFF0B0B0B),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      submitting ? 'Submitting...' : 'Submit',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (submitting) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: uploadProgress == 0 ? null : uploadProgress,
                    backgroundColor: const Color(0xFF2B2F35),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      uploadProgress == 0
                          ? 'Uploading...'
                          : 'Uploading ${(uploadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          child: _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < schema.fields.length; i++) ...[
                  _buildField(schema.fields[i]),
                  if (i != schema.fields.length - 1) const SizedBox(height: 18),
                ],
                AttachmentsBar(
                  items: attachments,
                  onAdd: () => _openAttachmentChooser(context),
                  onRemove: (i) => setState(() => attachments.removeAt(i)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------- UI components (same style you already used) -------------------- */

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2F35),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3B3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E6A66)),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          color: Color(0xFF69C1B8),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DarkDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DarkDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          dropdownColor: const Color(0xFF141414),
          hint: Text(hint, style: TextStyle(color: Colors.white.withOpacity(0.35))),
          style: const TextStyle(color: Colors.white),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DarkTapField extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DarkTapField({required this.text, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _RadioCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B2F35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF0F3DFF) : const Color(0xFF3A3A3A),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF0F3DFF),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- FAB MENU ---------------- */

class _FabMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onMic;
  final VoidCallback onVideo;
  final VoidCallback onCamera;

  const _FabMenu({
    required this.isOpen,
    required this.onToggle,
    required this.onMic,
    required this.onVideo,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniFab(show: isOpen, icon: Icons.camera_alt, onTap: onCamera),
        const SizedBox(height: 12),
        _MiniFab(show: isOpen, icon: Icons.videocam, onTap: onVideo),
        const SizedBox(height: 12),
        _MiniFab(show: isOpen, icon: Icons.mic, onTap: onMic),
        const SizedBox(height: 16),
        _MainFab(isOpen: isOpen, onTap: onToggle),
      ],
    );
  }
}

class _MainFab extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _MainFab({required this.isOpen, required this.onTap});

  @override
  State<_MainFab> createState() => _MainFabState();
}

class _MainFabState extends State<_MainFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didUpdateWidget(covariant _MainFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.isOpen ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final rotation = t * (math.pi / 2);
        return Transform.rotate(
          angle: rotation,
          child: FloatingActionButton(
            backgroundColor: t > 0.5 ? const Color(0xFFFF5A3D) : const Color(0xFF0F3DFF),
            onPressed: widget.onTap,
            child: Icon(
              t > 0.5 ? Icons.close : Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

class _MiniFab extends StatelessWidget {
  final bool show;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniFab({
    required this.show,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child));
      },
      child: show
          ? FloatingActionButton(
        key: ValueKey(icon),
        heroTag: icon.codePoint,
        mini: true,
        backgroundColor: const Color(0xFF0F3DFF),
        onPressed: onTap,
        child: Icon(icon, color: Colors.white),
      )
          : const SizedBox(key: ValueKey('hidden'), height: 0, width: 0),
    );
  }
}