import 'package:flutter/material.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/widgets/report_attachment_card.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  final String title;
  final ApiClient api;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.title,
    required this.api,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool loading = true;
  bool sendingCodeRedEmail = false;
  Map<String, dynamic>? report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      final result = await widget.api.getReportById(widget.reportId);

      if (!mounted) return;

      setState(() {
        report = result;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load report: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB3261E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }


  String _normalizeCategory(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  bool get _isCodeRed {
    final category = (report?['category'] ?? '').toString();
    return _normalizeCategory(category) == 'code_red';
  }

  Future<void> _sendCodeRedEmailAgain() async {
    if (sendingCodeRedEmail) return;

    setState(() {
      sendingCodeRedEmail = true;
    });

    try {
      await widget.api.resendCodeRedReportEmail(
        widget.reportId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Code Red email sent successfully',style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF097107),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to resend email: $error', style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFB3261E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sendingCodeRedEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeRed = _isCodeRed;

    return Scaffold(
      backgroundColor: codeRed
          ? const Color(0xFF12090A)
          : const Color(0xFF090B0F),
      appBar: AppBar(
        backgroundColor: codeRed
            ? const Color(0xFF1B090B)
            : const Color(0xFF090B0F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: loading ? null : _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: loading
            ? const _LoadingView()
            : report == null
            ? const _EmptyReportView()
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final createdAt = (report!['createdAt'] ?? '').toString();
    final fullname = (report!['fullname'] ?? '').toString();
    final companyId = (report!['companyID'] ?? '').toString();
    final reportTitle =
    (report!['title'] ?? widget.title).toString().trim();

    final reportCategory =
    (report!['category'] ?? 'General').toString().trim();

    final isCodeRed =
        _normalizeCategory(reportCategory) == 'code_red';
    final accentColor = isCodeRed
        ? const Color(0xFFFF3D3D)
        : const Color(0xFF4CC9F0);

    final displayFields = _parseDisplayFields(report!);

    final attachments = _parseAttachments(report!['attachments']);

    final images = attachments.where(_isImageAttachment).toList();
    final videos = attachments.where(_isVideoAttachment).toList();
    final documents = attachments
        .where(
          (attachment) =>
      !_isImageAttachment(attachment) &&
          !_isVideoAttachment(attachment),
    )
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: accentColor,
      backgroundColor: isCodeRed
          ? const Color(0xFF2A1013)
          : const Color(0xFF1B1F27),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportHeroCard(
              title: reportTitle,
              category: reportCategory,
              createdAtIso: createdAt,
              fullname: fullname,
              companyId: companyId,
            ),
            const SizedBox(height: 18),

            _SectionHeader(
              icon: Icons.description_outlined,
              title: 'Report Details',
              count: displayFields.length,
              accentColor: accentColor,
            ),
            const SizedBox(height: 10),

            if (displayFields.isEmpty)
              _EmptySectionCard(
                icon: Icons.notes_rounded,
                message: 'No report details were provided.',
                accentColor: accentColor,
              )
            else
              _ReportDetailsCard(
                fields: displayFields,
                accentColor: accentColor,
              ),

            if (isCodeRed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: sendingCodeRedEmail
                      ? null
                      : _sendCodeRedEmailAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF6D2529),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: sendingCodeRedEmail
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.mark_email_unread_outlined),
                  label: Text(
                    sendingCodeRedEmail
                        ? 'Sending Email...'
                        : 'Send Code Red Email Again',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),

                ),
              ),
            ],

            if (images.isNotEmpty) ...[
              const SizedBox(height: 22),
              _SectionHeader(
                icon: Icons.photo_library_outlined,
                title: 'Images',
                count: images.length,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              _AttachmentSection(
                attachments: images,
                accentColor: accentColor,
              ),
            ],

            if (videos.isNotEmpty) ...[
              const SizedBox(height: 22),
              _SectionHeader(
                icon: Icons.video_library_outlined,
                title: 'Videos',
                count: videos.length,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              _AttachmentSection(
                attachments: videos,
                accentColor: accentColor,
              ),
            ],

            if (documents.isNotEmpty) ...[
              const SizedBox(height: 22),
              _SectionHeader(
                icon: Icons.attach_file_rounded,
                title: 'Documents',
                count: documents.length,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              _AttachmentSection(
                attachments: documents,
                accentColor: accentColor,
              ),
            ],

            if (attachments.isEmpty) ...[
              const SizedBox(height: 22),
              _SectionHeader(
                icon: Icons.attach_file_rounded,
                title: 'Attachments',
                count: 0,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              _EmptySectionCard(
                icon: Icons.cloud_off_outlined,
                message: 'No images, videos, or documents attached.',
                accentColor: accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Reads the backend-generated displayFields first.
  ///
  /// Expected API format:
  /// {
  ///   "displayFields": [
  ///     {
  ///       "keyName": "guard_name",
  ///       "label": "Guard Name",
  ///       "value": "John Smith"
  ///     }
  ///   ]
  /// }
  ///
  /// If displayFields is unavailable, it falls back to report.fields.
  List<_DisplayField> _parseDisplayFields(Map<String, dynamic> reportData) {
    final List<_DisplayField> output = [];

    final dynamic rawDisplayFields = reportData['displayFields'];

    if (rawDisplayFields is List) {
      for (final item in rawDisplayFields) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);

        final keyName = (map['keyName'] ?? '').toString();
        final rawLabel = (map['label'] ?? '').toString();
        final value = map['value'];

        if (_shouldHideField(keyName, value)) continue;

        output.add(
          _DisplayField(
            keyName: keyName,
            label: _formatLabel(
              rawLabel.isNotEmpty ? rawLabel : keyName,
            ),
            value: _formatValue(value),
          ),
        );
      }

      if (output.isNotEmpty) {
        return output;
      }
    }

    final dynamic rawFields = reportData['fields'];

    if (rawFields is Map) {
      final fields = Map<String, dynamic>.from(rawFields);

      for (final entry in fields.entries) {
        if (_shouldHideField(entry.key, entry.value)) continue;

        output.add(
          _DisplayField(
            keyName: entry.key,
            label: _formatLabel(entry.key),
            value: _formatValue(entry.value),
          ),
        );
      }
    }

    return output;
  }

  bool _shouldHideField(String keyName, dynamic value) {
    final key = keyName.toLowerCase().trim();
    final stringValue = value?.toString().toLowerCase() ?? '';

    const hiddenKeys = {
      'postsiteid',
      'post_site_id',
      'postid',
      'post_id',
      'siteid',
      'site_id',
      'postsitename',
    };

    if (hiddenKeys.contains(key)) {
      return true;
    }

    if (stringValue.contains('res.cloudinary.com')) {
      return true;
    }

    if (stringValue.startsWith('http://') ||
        stringValue.startsWith('https://')) {
      final extension = _getExtension(stringValue);

      if (_imageExtensions.contains(extension) ||
          _videoExtensions.contains(extension)) {
        return true;
      }
    }

    return false;
  }

  String _formatLabel(String input) {
    if (input.trim().isEmpty) {
      return 'Field';
    }

    final cleanText = input
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    return cleanText
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) {
      final lower = word.toLowerCase();

      if (_uppercaseWords.contains(lower)) {
        return lower.toUpperCase();
      }

      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    })
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return 'Not provided';
    }

    if (value is bool) {
      return value ? 'Yes' : 'No';
    }

    if (value is List) {
      if (value.isEmpty) {
        return 'Not provided';
      }

      return value.map((item) => item.toString()).join(', ');
    }

    if (value is Map) {
      if (value.isEmpty) {
        return 'Not provided';
      }

      return value.entries
          .map((entry) => '${_formatLabel(entry.key.toString())}: ${entry.value}')
          .join('\n');
    }

    final text = value.toString().trim();

    return text.isEmpty ? 'Not provided' : text;
  }

  List<Map<String, dynamic>> _parseAttachments(dynamic raw) {
    final List<Map<String, dynamic>> output = [];

    if (raw is! List) {
      return output;
    }

    for (final attachment in raw) {
      if (attachment is Map) {
        output.add(
          Map<String, dynamic>.from(attachment),
        );
      } else if (attachment is String) {
        output.add({
          'secureUrl': attachment,
          'url': attachment,
        });
      }
    }

    return output;
  }

  bool _isImageAttachment(Map<String, dynamic> attachment) {
    final mimeType = _attachmentMimeType(attachment);
    final url = _attachmentUrl(attachment);
    final extension = _getExtension(url);

    return mimeType.startsWith('image/') ||
        _imageExtensions.contains(extension);
  }

  bool _isVideoAttachment(Map<String, dynamic> attachment) {
    final mimeType = _attachmentMimeType(attachment);
    final url = _attachmentUrl(attachment);
    final extension = _getExtension(url);

    return mimeType.startsWith('video/') ||
        _videoExtensions.contains(extension);
  }

  String _attachmentMimeType(Map<String, dynamic> attachment) {
    return (attachment['mimeType'] ??
        attachment['resourceType'] ??
        attachment['type'] ??
        '')
        .toString()
        .toLowerCase();
  }

  String _attachmentUrl(Map<String, dynamic> attachment) {
    return (attachment['secureUrl'] ??
        attachment['secure_url'] ??
        attachment['url'] ??
        attachment['path'] ??
        '')
        .toString();
  }

  String _getExtension(String value) {
    if (value.isEmpty) return '';

    final cleanValue = value.split('?').first;
    final dotIndex = cleanValue.lastIndexOf('.');

    if (dotIndex == -1) return '';

    return cleanValue.substring(dotIndex + 1).toLowerCase();
  }

  static const Set<String> _uppercaseWords = {
    'id',
    'gps',
    'nfc',
    'qr',
    'url',
    'ip',
    'api',
  };

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
  };

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
    '3gp',
  };
}

class _ReportHeroCard extends StatelessWidget {
  final String title;
  final String category;
  final String createdAtIso;
  final String fullname;
  final String companyId;

  const _ReportHeroCard({
    required this.title,
    required this.category,
    required this.createdAtIso,
    required this.fullname,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.tryParse(createdAtIso)?.toLocal();
    final formattedDate = dateTime == null
        ? 'Date unavailable'
        : _formatDateTime(dateTime);

    final badge = _badgeForCategory(category);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF252A34),
            Color(0xFF151922),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -24,
            child: Icon(
              Icons.assignment_outlined,
              size: 170,
              color: Colors.white.withOpacity(0.035),
            ),
          ),
          Positioned(
            right: 22,
            top: 22,
            child: Icon(
              Icons.verified_outlined,
              size: 28,
              color: badge.color.withOpacity(0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: badge.color.withOpacity(0.7),
                    ),
                  ),
                  child: Text(
                    badge.text,
                    style: TextStyle(
                      color: badge.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Official report record',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                _HeroMetaRow(
                  icon: Icons.schedule_rounded,
                  label: 'Submitted',
                  value: formattedDate,
                ),
                if (fullname.trim().isNotEmpty)
                  _HeroMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Reporter',
                    value: fullname,
                  ),
                if (companyId.trim().isNotEmpty)
                  _HeroMetaRow(
                    icon: Icons.business_outlined,
                    label: 'Company ID',
                    value: companyId,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${twoDigits(dateTime.day)}/'
        '${twoDigits(dateTime.month)}/'
        '${dateTime.year} at '
        '${twoDigits(hour)}:'
        '${twoDigits(dateTime.minute)} $period';
  }

  static _Badge _badgeForCategory(String category) {
    final value = category.trim();
    final normalized = value.toLowerCase();
    final badgeText = value.isEmpty ? 'GENERAL' : value.toUpperCase();

    if (normalized.contains('code red') ||
        normalized.contains('emergency') ||
        normalized.contains('critical')) {
      return _Badge(
        badgeText,
        const Color(0xFFFF3D00),
      );
    }

    if (normalized.contains('nfc')) {
      return _Badge(
        badgeText,
        const Color(0xFF9C6ADE),
      );
    }

    if (normalized.contains('qr')) {
      return _Badge(
        badgeText,
        const Color(0xFF7C4DFF),
      );
    }

    if (normalized.contains('incident') ||
        normalized.contains('break') ||
        normalized.contains('theft') ||
        normalized.contains('stolen')) {
      return _Badge(
        badgeText,
        const Color(0xFFFF6B4A),
      );
    }

    if (normalized.contains('inspection') ||
        normalized.contains('hourly') ||
        normalized.contains('patrol')) {
      return _Badge(
        badgeText,
        const Color(0xFF45D483),
      );
    }

    return _Badge(
      badgeText,
      const Color(0xFF4CC9F0),
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color accentColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportDetailsCard extends StatelessWidget {
  final List<_DisplayField> fields;
  final Color accentColor;

  const _ReportDetailsCard({
    required this.fields,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: 25,
            child: Icon(
              Icons.description_outlined,
              size: 155,
              color: Colors.white.withOpacity(0.018),
            ),
          ),
          Column(
            children: List.generate(
              fields.length,
                  (index) {
                final field = fields[index];
                final isLast = index == fields.length - 1;

                return _ReportDetailRow(
                  field: field,
                  showDivider: !isLast,
                  accentColor: accentColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailRow extends StatelessWidget {
  final _DisplayField field;
  final bool showDivider;
  final Color accentColor;

  const _ReportDetailRow({
    required this.field,
    required this.showDivider,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Text(
                  field.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: SelectableText(
                  field.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.white.withOpacity(0.055),
          ),
      ],
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  final List<Map<String, dynamic>> attachments;
  final Color accentColor;

  const _AttachmentSection({
    required this.attachments,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: List.generate(
          attachments.length,
              (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == attachments.length - 1 ? 0 : 12,
              ),
              child: ReportAttachmentCard(
                attachment: attachments[index],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color accentColor;

  const _EmptySectionCard({
    required this.icon,
    required this.message,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: accentColor.withOpacity(0.45),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF4CC9F0),
      ),
    );
  }
}

class _EmptyReportView extends StatelessWidget {
  const _EmptyReportView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.find_in_page_outlined,
              size: 54,
              color: Colors.white30,
            ),
            const SizedBox(height: 14),
            const Text(
              'No report found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'The report may have been removed or is temporarily unavailable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplayField {
  final String keyName;
  final String label;
  final String value;

  const _DisplayField({
    required this.keyName,
    required this.label,
    required this.value,
  });
}

class _Badge {
  final String text;
  final Color color;

  const _Badge(
      this.text,
      this.color,
      );
}