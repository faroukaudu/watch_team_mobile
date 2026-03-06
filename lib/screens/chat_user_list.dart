import "package:flutter/material.dart";
import '../chat/chat_api.dart';
import '../chat/app_user.dart';
import 'chat.dart';
import 'package:watch_team/chat/chat_socket.dart';

class UsersPage extends StatefulWidget {
  final ChatApi api;
  final String myUserId;

  const UsersPage({super.key, required this.api, required this.myUserId});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Future<List<AppUser>> _future;
  late final ChatSocket _socketClient;
  dynamic _socket; // or IO.Socket? depending on your socket class

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchUsers();

    _socketClient = ChatSocket(baseUrl: widget.api.baseUrl, myUserId: widget.myUserId);
    _socket = _socketClient.connect();

    _socket.on("message:notify", (data) {
      // refresh the list (or your inbox list if you later build /api/chats)
      setState(() {
        _future = widget.api.fetchUsers();
      });
    });
  }

  @override
  void dispose() {
    _socket?.off("message:notify");
    _socketClient.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Usersss")),
      body: FutureBuilder<List<AppUser>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          final users = (snap.data ?? []).where((u) => u.id != widget.myUserId).toList();
          if (users.isEmpty) return const Center(child: Text("No users found"));

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  child: Text(
                    (u.name.isNotEmpty ? u.name[0].toUpperCase() : "?"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  u.email.isNotEmpty ? u.email : "No email",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  final chatId = await widget.api.getOrCreateDirectChat(otherUserId: u.id);
                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        api: widget.api,
                        myUserId: widget.myUserId,
                        otherUser: u,
                        chatId: chatId,
                      ),
                    ),
                  );
                },
              );

            },
          );
        },
      ),
    );
  }
}
