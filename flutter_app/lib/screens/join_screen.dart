import 'dart:async';
import 'package:flutter/material.dart';
import '../services/lobby_service.dart';
import 'lobby_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final LobbyService _lobbyService = LobbyService();
  List<Map<String, dynamic>> _lobbies = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLobbies();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchLobbies());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lobbyService.dispose();
    super.dispose();
  }

  Future<void> _fetchLobbies() async {
    try {
      final lobbies = await _lobbyService.fetchLobbies();
      if (mounted) {
        setState(() {
          _lobbies = lobbies;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _joinLobby(String id, String role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LobbyScreen(lobbyId: id, role: role),
      ),
    );
  }

  void _createRandomLobby() {
    final id = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    _joinLobby(id, 'player');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LiveServer Lobbies')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _createRandomLobby,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Random Lobby'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: _lobbies.isEmpty
                      ? const Center(child: Text('No active lobbies found.'))
                      : ListView.builder(
                          itemCount: _lobbies.length,
                          itemBuilder: (context, index) {
                            final lobby = _lobbies[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text('Lobby ${lobby['id']}'),
                                subtitle: Text('${lobby['count']} users active'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => _joinLobby(lobby['id'], 'viewer'),
                                      child: const Text('Watch'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _joinLobby(lobby['id'], 'player'),
                                      child: const Text('Play'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
