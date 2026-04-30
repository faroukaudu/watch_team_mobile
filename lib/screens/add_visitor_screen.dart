import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:watch_team/global.dart';
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/services/cloudinary_uploader.dart';
import 'package:watch_team/services/media_capture_service.dart';
import 'package:watch_team/services/bytes_to_file.dart';
import 'package:watch_team/screens/report/signature_screen.dart';

class AddVisitorScreen extends StatefulWidget {
  final String postSiteId;
  final String postSiteName;

  const AddVisitorScreen({
    super.key,
    required this.postSiteId,
    required this.postSiteName,
  });

  @override
  State<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  final ApiClient api = ApiClient(baseUrl: baseUrl);
  final CloudinaryUploader cloudinary = CloudinaryUploader(Dio());
  final MediaCaptureService media = MediaCaptureService();

  final formKey = GlobalKey<FormState>();

  final visitorNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();

  String sex = "Male";
  bool firstTimeVisiting = true;

  File? faceFile;
  File? idFile;
  Uint8List? signatureBytes;

  bool saving = false;
  double progress = 0;

  @override
  void dispose() {
    visitorNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    purposeCtrl.dispose();
    super.dispose();
  }

  Future<File?> pickGalleryImage() async {
    final assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.image,
      ),
    );

    if (assets == null || assets.isEmpty) return null;
    return await assets.first.file;
  }

  Map<String, dynamic> cloudPayload(Map<String, dynamic> cloud, String kind) {
    return {
      'kind': kind,
      'publicId': cloud['public_id'],
      'secureUrl': cloud['secure_url'],
      'resourceType': cloud['resource_type'],
      'format': cloud['format'],
      'bytes': cloud['bytes'],
      'originalName': cloud['original_filename'],
    };
  }

  Future<Map<String, dynamic>?> uploadFile({
    required String visitorTempId,
    required String kind,
    required File? file,
  }) async {
    if (file == null) return null;

    final sign = await api.getVisitorCloudinarySign(
      visitorTempId: visitorTempId,
      kind: kind,
    );

    final cloud = await cloudinary.upload(sign: sign, file: file);
    return cloudPayload(cloud, kind);
  }

  Future<void> submitVisitor() async {
    if (saving) return;

    if (!formKey.currentState!.validate()) return;

    if (faceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please attach visitor face")),
      );
      return;
    }

    if (idFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please attach visitor ID")),
      );
      return;
    }

    if (signatureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture visitor signature")),
      );
      return;
    }

    setState(() {
      saving = true;
      progress = 0;
    });

    try {
      final visitorTempId = "visitor-${DateTime.now().millisecondsSinceEpoch}";

      final signatureFile = await bytesToTempPng(signatureBytes!);

      final visitorFace = await uploadFile(
        visitorTempId: visitorTempId,
        kind: "visitorFace",
        file: faceFile,
      );
      setState(() => progress = .33);

      final visitorIdCard = await uploadFile(
        visitorTempId: visitorTempId,
        kind: "visitorIdCard",
        file: idFile,
      );
      setState(() => progress = .66);

      final signature = await uploadFile(
        visitorTempId: visitorTempId,
        kind: "signature",
        file: signatureFile,
      );
      setState(() => progress = .9);

      final companyId =
      (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
      final guardId = (SessionData.userProfile?['_id'] ?? '').toString();
      final guardName =
      (SessionData.userProfile?['fullname'] ?? SessionData.userProfile?['email'] ?? '')
          .toString();

      await api.createVisitor({
        'companyId': companyId,
        'postSiteId': widget.postSiteId,
        'postSiteName': widget.postSiteName,
        'guardId': guardId,
        'guardName': guardName,
        'visitorName': visitorNameCtrl.text.trim(),
        'sex': sex,
        'phoneNumber': phoneCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'purposeOfVisit': purposeCtrl.text.trim(),
        'firstTimeVisiting': firstTimeVisiting,
        'visitorFace': visitorFace,
        'visitorIdCard': visitorIdCard,
        'signature': signature,
      });

      setState(() => progress = 1);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visitor saved successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save visitor: $e")),
      );
    }
  }

  Widget inputCard({required Widget child}) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: text.withOpacity(.08)),
      ),
      child: child,
    );
  }

  Widget imageAttachCard({
    required String title,
    required File? file,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return inputCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                file,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: text.withOpacity(.08)),
              ),
              child: Icon(Icons.image, color: muted, size: 42),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Snap"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: text.withOpacity(.65)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: text.withOpacity(.12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final primary = theme.primaryColor;
    final text = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        centerTitle: true,
        title: Text(
          "Add Visitor",
          style: TextStyle(color: text, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: card,
          border: Border(top: BorderSide(color: text.withOpacity(.08))),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saving) ...[
                LinearProgressIndicator(value: progress, color: primary),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : submitVisitor,
                  icon: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.save),
                  label: Text(saving ? "Saving Visitor..." : "Save Visitor"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.postSiteName,
              style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text("Date and time will be captured automatically", style: TextStyle(color: muted)),
            const SizedBox(height: 16),

            inputCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: visitorNameCtrl,
                    style: TextStyle(color: text),
                    decoration: inputDecoration("Visitor Name"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Visitor name is required" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: sex,
                    dropdownColor: card,
                    style: TextStyle(color: text),
                    decoration: inputDecoration("Sex"),
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (v) => setState(() => sex = v ?? "Male"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: text),
                    decoration: inputDecoration("Phone Number"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: text),
                    decoration: inputDecoration("Email"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: purposeCtrl,
                    maxLines: 3,
                    style: TextStyle(color: text),
                    decoration: inputDecoration("Purpose of Visit"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Purpose is required" : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: firstTimeVisiting,
                    activeColor: primary,
                    contentPadding: EdgeInsets.zero,
                    title: Text("First Time Visiting?", style: TextStyle(color: text, fontWeight: FontWeight.w700)),
                    subtitle: Text(firstTimeVisiting ? "Yes" : "No", style: TextStyle(color: muted)),
                    onChanged: (v) => setState(() => firstTimeVisiting = v),
                  ),
                ],
              ),
            ),

            imageAttachCard(
              title: "Snap and Attach Visitor Face",
              file: faceFile,
              onCamera: () async {
                final f = await media.captureImageFromCamera();
                if (f != null) setState(() => faceFile = f);
              },
              onGallery: () async {
                final f = await pickGalleryImage();
                if (f != null) setState(() => faceFile = f);
              },
            ),

            imageAttachCard(
              title: "Snap and Attach Visitor ID",
              file: idFile,
              onCamera: () async {
                final f = await media.captureImageFromCamera();
                if (f != null) setState(() => idFile = f);
              },
              onGallery: () async {
                final f = await pickGalleryImage();
                if (f != null) setState(() => idFile = f);
              },
            ),

            inputCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Visitor Signature", style: TextStyle(color: text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final result = await Navigator.push<Uint8List?>(
                        context,
                        MaterialPageRoute(builder: (_) => const SignatureScreen()),
                      );
                      if (result != null) setState(() => signatureBytes = result);
                    },
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: text.withOpacity(.08)),
                      ),
                      child: signatureBytes == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw, color: muted),
                          const SizedBox(height: 6),
                          Text("Tap to Sign", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                        ],
                      )
                          : Center(
                        child: Text(
                          "Signature Added",
                          style: TextStyle(color: primary, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}