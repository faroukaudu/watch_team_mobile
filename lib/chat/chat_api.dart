import "dart:convert";
import "package:http/http.dart" as http;
import 'app_user.dart';

class ChatApi {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ChatApi({
    required this.baseUrl,
    required String myUserId,
  }) : defaultHeaders = {
    "Content-Type": "application/json",
    "x-user-id": myUserId, // ✅ important
  };

  // You NEED an endpoint for users. If you already have one, replace this URL.
  Future<List<AppUser>> fetchUsers() async {
    final r = await http.get(Uri.parse("$baseUrl/api/users"), headers: defaultHeaders);
    if (r.statusCode != 200) throw Exception("fetchUsers failed: ${r.statusCode}");
    final data = jsonDecode(r.body);
    final list = (data is List) ? data : (data["users"] ?? []);
    return List<Map<String, dynamic>>.from(list).map(AppUser.fromJson).toList();
  }

  Future<String> getOrCreateDirectChat({required String otherUserId}) async {
    final r = await http.post(
      Uri.parse("$baseUrl/api/chats/direct"),
      headers: defaultHeaders,
      body: jsonEncode({"otherUserId": otherUserId}),
    );

    if (r.statusCode != 200) {
      throw Exception("direct chat failed: ${r.statusCode} ${r.body}");
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    if (j["ok"] != true) throw Exception("direct chat failed: ${j["error"]}");
    return j["chatId"].toString();
  }

  Future<List<ChatMessage>> fetchMessages({required String chatId, int limit = 50}) async {
    final r = await http.get(
      Uri.parse("$baseUrl/api/messages?chatId=$chatId&limit=$limit"),
      headers: defaultHeaders,
    );

    if (r.statusCode != 200) {
      throw Exception("fetchMessages failed: ${r.statusCode} ${r.body}");
    }

    final list = jsonDecode(r.body) as List;
    final msgs = list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();

    // API returns newest first; reverse to show oldest -> newest
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }
}
