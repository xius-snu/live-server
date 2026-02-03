import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lobby_service.dart';
import '../services/user_service.dart';

class LobbyScreen extends StatefulWidget {
  final String lobbyId;
  final String role; // 'player' or 'viewer'

  const LobbyScreen({super.key, required this.lobbyId, required this.role});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final LobbyService _service = LobbyService();
  int _value = 0;
  int _viewers = 0;
  String _status = 'Connecting...';
  List<Map<String, dynamic>> _activeUsers = [];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    final userService = Provider.of<UserService>(context, listen: false);
    if (!userService.hasUser) {
      setState(() => _status = 'Error: No User Identified');
      return;
    }

    _service.connectToLobby(
      widget.lobbyId, 
      widget.role,
      userService.userId!,
      userService.username!
    );

    _service.updates.listen((data) {
      if (mounted) {
        setState(() {
          if (data.containsKey('v')) _value = data['v'];
          if (data.containsKey('c')) _viewers = data['c'];
          
          if (data.containsKey('viewers') || data.containsKey('players')) {
            final List<dynamic> viewers = data['viewers'] ?? [];
            final List<dynamic> players = data['players'] ?? [];
            _activeUsers = [
              ...players.map((e) => Map<String, dynamic>.from(e)..addAll({'role': 'Player'})), 
              ...viewers.map((e) => Map<String, dynamic>.from(e)..addAll({'role': 'Viewer'}))
            ];
          }
          
          _status = 'Live';
        });
      }
    }, onError: (err) {
      if (mounted) setState(() => _status = 'Error: $err');
    });
  }

  @override
  void dispose() {
    _service.disconnect();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlayer = widget.role == 'player';

    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby ${widget.lobbyId} (${widget.role})'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status == 'Live' ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
             child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_value',
                  style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 10),
                Text(
                  'Active Users: $_viewers',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Connected Users', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: _activeUsers.length,
              itemBuilder: (context, index) {
                final user = _activeUsers[index];
                return ListTile(
                  leading: Icon(user['role'] == 'Player' ? Icons.gamepad : Icons.remove_red_eye),
                  title: Text(user['name'] ?? 'Unknown'),
                  subtitle: Text(user['role']),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isPlayer
          ? Padding(
            padding: const EdgeInsets.all(30.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.large(
                    heroTag: 'dec',
                    backgroundColor: Colors.redAccent,
                    onPressed: () => _service.sendAction('DEC'),
                    child: const Icon(Icons.remove),
                  ),
                  FloatingActionButton.large(
                    heroTag: 'inc',
                    backgroundColor: Colors.green,
                    onPressed: () => _service.sendAction('INC'),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
          )
          : null,
    );
  }
}
