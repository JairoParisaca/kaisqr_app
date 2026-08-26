import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;

  Stream<Map<String, dynamic>> connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    return _channel!.stream.map((dynamic event) {
      final decoded = jsonDecode(event.toString());
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'tipo': 'mensaje_desconocido'};
    });
  }

  Future<void> waitUntilReady() async {
    await _channel?.ready;
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
