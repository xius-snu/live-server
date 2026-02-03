import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class LobbyService {
  // Render hosted server
  // Render hosted server
  // static const String _host = 'live-server-4c3n.onrender.com';
  
  // Local development server for Debug, Render for Release
  static String get _host {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return '10.0.2.2:3000';
      }
      return 'localhost:3000';
    }
    return 'live-server-4c3n.onrender.com';
  }

  static String get _baseUrl => 'http://$_host';
  static String get _wsUrl => 'ws://$_host';

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

  void connectToLobby(String lobbyId, String role, String userId, String username) {
    final uri = Uri.parse('$_wsUrl/ws/$lobbyId?role=$role&userId=$userId&username=$username');
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
