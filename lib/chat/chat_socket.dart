import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  final String baseUrl;
  final String myUserId;

  IO.Socket? _socket;

  ChatSocket({required this.baseUrl, required this.myUserId});

  IO.Socket connect() {
    final s = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({"userId": myUserId})
          .enableAutoConnect()
          .build(),
    );

    _socket = s;
    return s;
  }

  void dispose() {
    _socket?.offAny();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
