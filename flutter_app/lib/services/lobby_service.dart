import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class LobbyService {
  // Use localhost for Windows/Web. use 10.0.2.2 for Android Emulator.
  // For now, defaulting to localhost since we are targeting Windows desktop primarily.
  static const String _baseUrl = 'http://localhost:3000';
  static const String _wsUrl = 'ws://localhost:3000';

  Future<List<Map<String, dynamic>>> fetchLobbies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/lobbies'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load lobbies');
      }
    } catch (e) {
      throw Exception('Error fetching lobbies: $e');
    }
  }

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _updateController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get updates => _updateController.stream;

  void connectToLobby(String lobbyId, String role) {
    final uri = Uri.parse('$_wsUrl/ws/$lobbyId?role=$role');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((message) {
      try {
        final data = json.decode(message);
        _updateController.add(data);
      } catch (e) {
        print('Error parsing message: $e');
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket closed');
    });
  }

  void sendAction(String action) {
    if (_channel != null) {
      _channel!.sink.add(json.encode({'action': action}));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
  
  void dispose() {
    _updateController.close();
  }
}
