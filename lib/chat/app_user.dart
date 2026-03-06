class AppUser {
  final String id;
  final String name;
  final String email;

  AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: j["_id"].toString(),
      name: (j["fullname"] ?? j["name"] ?? j["email"] ?? "User").toString(),
      email: (j["email"] ?? "").toString(),
    );
  }
}

class ChatMessage {
  final String id;          // server _id or tempId for pending
  final String chatId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final bool pending;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.pending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final created = j["createdAt"];
    DateTime dt;
    if (created is String) {
      dt = DateTime.tryParse(created) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }

    return ChatMessage(
      id: j["_id"].toString(),
      chatId: j["chatId"].toString(),
      senderId: j["senderId"].toString(),
      body: (j["body"] ?? "").toString(),
      createdAt: dt,
      pending: false,
    );
  }
}
