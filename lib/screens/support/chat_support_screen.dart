
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/session_data.dart';
import 'package:watch_team/services/support_service.dart';
import 'package:watch_team/widgets/security_ui.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  late final SupportService service;
  bool loading = true;
  List<Map<String, dynamic>> admins = [];

  @override
  void initState() {
    super.initState();
    service = SupportService(
      baseUrl: g.baseUrl,
      userId: (SessionData.userProfile?['_id'] ?? '').toString(),
    );
    load();
  }

  Future<void> load() async {
    try {
      final result = await service.getSupportAdmins();
      if (!mounted) return;
      setState(() {
        admins = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load support admins: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecurityPage(
      title: 'Chat Support',
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: SecurityColors.primary),
            )
          : admins.isEmpty
              ? const Center(
                  child: Text(
                    'No support administrator is available.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SecuritySectionCard(
                      child: Row(
                        children: [
                          Icon(Icons.support_agent_rounded,
                              color: SecurityColors.primary, size: 34),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose an administrator to begin a private support conversation.',
                              style:
                                  TextStyle(color: Colors.white70, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...admins.map((admin) {
                      final role = (admin['role'] ?? 'Support Admin').toString();
                      final isPlatform =
                          role.toLowerCase().contains('platform');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SecuritySectionCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      SecurityColors.primary.withOpacity(.14),
                                  child: Text(
                                    (admin['fullname'] ?? 'A')
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: SecurityColors.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  right: 0,
                                  bottom: 1,
                                  child: CircleAvatar(
                                    radius: 6,
                                    backgroundColor: SecurityColors.green,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              (admin['fullname'] ?? 'Administrator').toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isPlatform
                                              ? SecurityColors.red
                                              : SecurityColors.primary)
                                          .withOpacity(.14),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: isPlatform
                                            ? SecurityColors.red
                                            : SecurityColors.primary,
                                      ),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        color: isPlatform
                                            ? SecurityColors.red
                                            : SecurityColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    (admin['email'] ?? '').toString(),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chat_bubble_outline_rounded,
                                color: SecurityColors.primary),
                            onTap: () async {
                              final adminId = admin['_id']?.toString() ?? '';
                              if (adminId.isEmpty) return;
                              final chatId = await service.openChat(adminId);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SupportConversationScreen(
                                    service: service,
                                    chatId: chatId,
                                    admin: admin,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class SupportConversationScreen extends StatefulWidget {
  final SupportService service;
  final String chatId;
  final Map<String, dynamic> admin;

  const SupportConversationScreen({
    super.key,
    required this.service,
    required this.chatId,
    required this.admin,
  });

  @override
  State<SupportConversationScreen> createState() =>
      _SupportConversationScreenState();
}

class _SupportConversationScreenState extends State<SupportConversationScreen> {
  final controller = TextEditingController();
  bool loading = true;
  bool sending = false;
  List<Map<String, dynamic>> messages = [];

  String get myId => (SessionData.userProfile?['_id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final result = await widget.service.getMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      messages = result;
      loading = false;
    });
  }

  Future<void> send() async {
    final body = controller.text.trim();
    if (body.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await widget.service.sendMessage(
        chatId: widget.chatId,
        receiverId: widget.admin['_id'].toString(),
        body: body,
      );
      controller.clear();
      await load();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = (widget.admin['role'] ?? 'Support Admin').toString();

    return Scaffold(
      backgroundColor: SecurityColors.background,
      appBar: AppBar(
        backgroundColor: SecurityColors.background,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0x2219B5FE),
              child: Icon(Icons.admin_panel_settings_outlined,
                  color: SecurityColors.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (widget.admin['fullname'] ?? 'Administrator').toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: SecurityColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: SecurityColors.primary),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final message = messages[index];
                      final mine = message['senderId']?.toString() == myId;
                      final time = DateTime.tryParse(
                        (message['createdAt'] ?? '').toString(),
                      )?.toLocal();

                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                          decoration: BoxDecoration(
                            color: mine
                                ? SecurityColors.primary
                                : SecurityColors.surface2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(mine ? 16 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 16),
                            ),
                            border: mine
                                ? null
                                : Border.all(color: SecurityColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  (message['body'] ?? '').toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time == null
                                    ? ''
                                    : DateFormat('hh:mm a').format(time),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.55),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: SecurityColors.surface,
                border: Border(top: BorderSide(color: SecurityColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a secure support message...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: SecurityColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  IconButton.filled(
                    onPressed: sending ? null : send,
                    style: IconButton.styleFrom(
                      backgroundColor: SecurityColors.primary,
                    ),
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
