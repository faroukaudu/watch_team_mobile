import "package:flutter/material.dart";
import "package:watch_team/global.dart" as g;
import "package:watch_team/session_data.dart";

import "package:watch_team/chat/chat_api.dart";
import "package:watch_team/screens/chat_user_list.dart"; // <-- where your UsersPage class is

class ChatUserListScreen extends StatelessWidget {
  const ChatUserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUserId = SessionData.userProfile!["_id"].toString();
    final api = ChatApi(baseUrl: g.baseUrl, myUserId: myUserId);

    return UsersPage(
      api: api,
      myUserId: myUserId,
    );
  }
}