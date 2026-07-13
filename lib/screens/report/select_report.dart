import 'package:flutter/material.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/screens/report/send_report.dart';
import 'package:watch_team/services/api_client.dart';

class SelectReportScreen extends StatefulWidget {
  const SelectReportScreen({super.key});

  @override
  State<SelectReportScreen> createState() => _SelectReportScreenState();
}

class _SelectReportScreenState extends State<SelectReportScreen> {
  static final String baseUrl = '${g.baseUrl}';
  static const String apiPrefix = '';

  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final api = ApiClient(baseUrl: baseUrl, apiPrefix: apiPrefix);
      final items = await api.listReportTemplates();

      if (!mounted) return;
      setState(() {
        _templates = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load templates: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTemplates {
    if (_query.isEmpty) return _templates;
    final q = _query.toLowerCase();

    return _templates.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final description = (t['description'] ?? '').toString().toLowerCase();
      final category = (t['category'] ?? '').toString().toLowerCase();
      return title.contains(q) || description.contains(q) || category.contains(q);
    }).toList();
  }

  String _subtitleFor(Map<String, dynamic> item) {
    final description = (item['description'] ?? '').toString().trim();
    if (description.isNotEmpty) return description;
    return 'Tap to open this report template.';
  }

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
        title: const Text(
          'Select Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              _SearchBar(
                controller: _searchCtrl,
                onClear: () => _searchCtrl.clear(),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredTemplates.isEmpty
                    ? const _EmptyResult()
                    : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: _filteredTemplates.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _filteredTemplates[index];

                    return _TemplateCard(
                      title: (item['title'] ?? '').toString(),
                      subtitle: _subtitleFor(item),
                      category: (item['category'] ?? 'general').toString(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportFormScreen(
                              reportTitle: (item['title'] ?? '').toString(),
                              templateId: (item['_id'] ?? '').toString(),
                              category: (item['category'] ?? 'general').toString(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search here...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Container(
            width: 58,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.onTap,
  });

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'standard':
        return Colors.green;
      case 'incident':
        return Colors.orange;
      case 'general':
        return Colors.black;
      case 'log':
        return Colors.blueGrey;
      case 'nfc':
        return Colors.purple;
      case 'code_red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _categoryBackground(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return const Color(0xFF1A1A1A);
      default:
        return _categoryColor(category).withOpacity(0.15);
    }
  }

  Color _categoryTextColor(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Colors.white;
      default:
        return _categoryColor(category);
    }
  }

  Color _categoryBorderColor(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return const Color(0xFF3A3A3A);
      default:
        return _categoryColor(category).withOpacity(0.45);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeBg = _categoryBackground(category);
    final badgeText = _categoryTextColor(category);
    final badgeBorder = _categoryBorderColor(category);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: badgeText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No report template found.',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
    );
  }
}