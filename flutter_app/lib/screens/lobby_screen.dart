import 'package:flutter/material.dart';
import '../services/lobby_service.dart';

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

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _service.connectToLobby(widget.lobbyId, widget.role);
    _service.updates.listen((data) {
      if (mounted) {
        setState(() {
          if (data.containsKey('v')) _value = data['v'];
          if (data.containsKey('c')) _viewers = data['c'];
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_value',
              style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),
            Text(
              'Active Users: $_viewers',
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ],
        ),
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
