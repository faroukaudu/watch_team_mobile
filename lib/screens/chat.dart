import "dart:math";
import "package:flutter/material.dart";

import "package:socket_io_client/socket_io_client.dart" as IO; // ✅ real Socket.IO type
import "package:watch_team/chat/chat_socket.dart";            // ✅ your ChatSocket class

import "package:watch_team/chat/chat_api.dart";
import "package:watch_team/chat/app_user.dart";

// import 'package:watch_team/chat/app_user.dart';

class ChatPage extends StatefulWidget {



  final ChatApi api;
  final String myUserId;
  final AppUser otherUser;
  final String chatId;

  const ChatPage({
    super.key,
    required this.api,
    required this.myUserId,
    required this.otherUser,
    required this.chatId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];

  late final ChatSocket _socketClient;
  IO.Socket? _socket;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _socketClient = ChatSocket(
      baseUrl: widget.api.baseUrl,
      myUserId: widget.myUserId,
    );

    _socket = _socketClient.connect(); // ✅ now you get the socket directly

    _socket!.onConnect((_) {
      _socket!.emit("chat:join", {"chatId": widget.chatId});
    });

    _socket!.on("message:new", (data) {
      final map = _asMap(data);

      // Build ChatMessage using your existing model
      final msg = ChatMessage.fromJson(map);

      // Only accept messages for this chat
      if (msg.chatId != widget.chatId) return;

      setState(() {
        // If this is my message coming back, server includes tempId
        final tempId = (map["tempId"] ?? "").toString();

        if (tempId.isNotEmpty) {
          // replace pending local message whose id == tempId
          final idx = _messages.indexWhere((m) => m.id == tempId && m.pending);
          if (idx != -1) {
            _messages[idx] = msg; // replace pending with server msg
            return;
          }
        }

        // otherwise append
        _messages.add(msg);
      });

      _scrollToBottom();
    });



    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final rows = await widget.api.fetchMessages(chatId: widget.chatId, limit: 80);
      setState(() {
        _messages
          ..clear()
          ..addAll(rows);
        _loading = false;
      });
      _scrollToBottom(jump: true);
    } catch (e) {
      setState(() => _loading = false);
      // If you get 401 here, it’s your ensureAuth/cookies issue.
      // Socket will still deliver realtime messages.
    }
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent + 120;
    if (jump) {
      _scroll.jumpTo(max);
    } else {
      _scroll.animateTo(max, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    // temp message while waiting for server
    final tempId = "${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}";
    final temp = ChatMessage(
      id: tempId,
      chatId: widget.chatId,
      senderId: widget.myUserId,
      body: text,
      createdAt: DateTime.now(),
      pending: true,
    );

    setState(() => _messages.add(temp));
    _scrollToBottom();

    _socket?.emitWithAck(
      "message:send",
      {"chatId": widget.chatId, "body": text, "tempId": tempId},
      ack: (ack) {
        final a = _asMap(ack);

        // If server responded ok, we can stop pending right away.
        if (a["ok"] == true && a["message"] != null) {
          final serverMap = _asMap(a["message"]);
          final serverMsg = ChatMessage.fromJson(serverMap);

          if (serverMsg.chatId != widget.chatId) return;

          setState(() {
            final idx = _messages.indexWhere((m) => m.id == tempId && m.pending);
            if (idx != -1) {
              _messages[idx] = serverMsg; // replace pending
            } else {
              _messages.add(serverMsg);
            }
          });

          _scrollToBottom();
        } else {
          // If failed: just remove pending or stop pending indicator
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == tempId && m.pending);
            if (idx != -1) {
              // easiest: remove it, or keep it but stop pending
              final old = _messages[idx];
              _messages[idx] = ChatMessage(
                id: old.id,
                chatId: old.chatId,
                senderId: old.senderId,
                body: old.body,
                createdAt: old.createdAt,
                pending: false,
              );
            }
          });
        }
      },
    );


  }

  @override
  void dispose() {
    _socket?.off("message:new");
    _socketClient.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUser.name)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMe = m.senderId == widget.myUserId;
                return _Bubble(
                  text: m.body,
                  isMe: isMe,
                  pending: m.pending,
                  time: m.createdAt,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: "Type a message…",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text("Send"),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool pending;
  final DateTime time;

  const _Bubble({
    required this.text,
    required this.isMe,
    required this.pending,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? Colors.blue.shade600 : Colors.grey.shade300;
    final fg = isMe ? Colors.white : Colors.black87;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMe ? 14 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 14),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(color: fg, fontSize: 15)),
            const SizedBox(height: 4),
            Opacity(
              opacity: 0.7,
              child: Text(
                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
                    "${pending ? " • sending…" : ""}",
                style: TextStyle(color: fg, fontSize: 11),
              ),
            )
          ],
        ),
      ),
    );
  }
}
