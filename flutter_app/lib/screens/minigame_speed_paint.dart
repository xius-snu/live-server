import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SpeedPaintMinigame extends StatefulWidget {
  const SpeedPaintMinigame({super.key});

  @override
  State<SpeedPaintMinigame> createState() => _SpeedPaintMinigameState();
}

class _SpeedPaintMinigameState extends State<SpeedPaintMinigame>
    with TickerProviderStateMixin {
  static const _accentColor = Color(0xFFE8734A);
  static const _bgColor = Color(0xFF1A1A2E);
  static const _gameDuration = 60;

  final _random = Random();

  // Game states
  bool _started = false;
  bool _finished = false;

  // Timer
  int _secondsLeft = _gameDuration;
  Timer? _countdownTimer;

  // Wall painting
  double _wallFill = 0.0;
  Color _wallColor = Colors.grey;
  int _wallsCompleted = 0;

  // Personal best
  int _personalBest = 0;

  // Leaderboard
  late List<_LeaderboardEntry> _leaderboard;

  @override
  void initState() {
    super.initState();
    _leaderboard = _generateFakeLeaderboard();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  List<_LeaderboardEntry> _generateFakeLeaderboard() {
    return [
      _LeaderboardEntry('PaintMaster99', 18),
      _LeaderboardEntry('SpeedDemon', 15),
      _LeaderboardEntry('RollerKing', 13),
      _LeaderboardEntry('WallSmasher', 11),
      _LeaderboardEntry('QuickBrush', 9),
    ];
  }

  Color _randomWallColor() {
    final colors = [
      const Color(0xFF4A90D9),
      const Color(0xFF50C878),
      const Color(0xFFE8734A),
      const Color(0xFFF5C542),
      const Color(0xFFA855F7),
      const Color(0xFFFF6B8A),
      const Color(0xFF00CED1),
      const Color(0xFFFF8C00),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _startGame() {
    setState(() {
      _started = true;
      _finished = false;
      _secondsLeft = _gameDuration;
      _wallsCompleted = 0;
      _wallFill = 0.0;
      _wallColor = _randomWallColor();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _endGame() {
    _countdownTimer?.cancel();
    setState(() {
      _finished = true;
      if (_wallsCompleted > _personalBest) {
        _personalBest = _wallsCompleted;
      }
      // Insert player into leaderboard
      _leaderboard = _generateFakeLeaderboard();
      _leaderboard.add(_LeaderboardEntry('You', _wallsCompleted));
      _leaderboard.sort((a, b) => b.score.compareTo(a.score));
      if (_leaderboard.length > 6) {
        _leaderboard = _leaderboard.sublist(0, 6);
      }
    });
  }

  void _onTapWall() {
    if (!_started || _finished) return;

    setState(() {
      final fillAmount = 0.10 + _random.nextDouble() * 0.05; // 10-15%
      _wallFill = (_wallFill + fillAmount).clamp(0.0, 1.0);

      if (_wallFill >= 0.90) {
        _wallsCompleted++;
        _wallFill = 0.0;
        _wallColor = _randomWallColor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                _buildHeader(),
                if (!_started && !_finished) _buildStartScreen(),
                if (_started && !_finished) Expanded(child: _buildGameplay()),
              ],
            ),
            // Results overlay
            if (_finished) _buildResultsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'Speed Paint',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (_started && !_finished)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _secondsLeft <= 10
                    ? Colors.red.withOpacity(0.3)
                    : _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _secondsLeft <= 10 ? Colors.red : _accentColor,
                  width: 2,
                ),
              ),
              child: Text(
                '${_secondsLeft}s',
                style: TextStyle(
                  color: _secondsLeft <= 10 ? Colors.red : _accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flash_on, size: 80, color: _accentColor),
          const SizedBox(height: 20),
          const Text(
            'Speed Paint',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Paint as many walls as you can in 60 seconds!\nTap to fill each wall. Complete at 90%.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
            child: const Text(
              'PLAY',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          if (_personalBest > 0) ...[
            const SizedBox(height: 20),
            Text(
              'Personal Best: $_personalBest walls',
              style: TextStyle(
                color: _accentColor.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameplay() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Walls completed counter
        Text(
          'Walls: $_wallsCompleted',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        // Fill percentage
        Text(
          '${(_wallFill * 100).toInt()}% filled',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        // The wall to paint
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTapDown: (_) => _onTapWall(),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _accentColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Fill from bottom
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: _wallFill,
                            widthFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _wallColor.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 90% threshold line
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: double.infinity,
                        child: FractionallySizedBox(
                          heightFactor: 0.90,
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            children: [
                              Container(
                                height: 2,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Tap hint
                      Center(
                        child: Text(
                          'TAP!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.15),
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildResultsOverlay() {
    final reward = 500 * _wallsCompleted;
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF222240),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _accentColor, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TIME\'S UP!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                // Score
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_wallsCompleted',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Walls Painted',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Personal best
                Text(
                  'Personal Best: $_personalBest',
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // Reward
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_money, color: Colors.greenAccent),
                      Text(
                        '+$reward Cash',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Leaderboard
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_leaderboard.length, (i) {
                        final entry = _leaderboard[i];
                        final isPlayer = entry.name == 'You';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isPlayer
                                ? _accentColor.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '#${i + 1}',
                                  style: TextStyle(
                                    color: i < 3
                                        ? _accentColor
                                        : Colors.white54,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.name,
                                  style: TextStyle(
                                    color: isPlayer
                                        ? _accentColor
                                        : Colors.white,
                                    fontWeight: isPlayer
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.score} walls',
                                style: TextStyle(
                                  color: isPlayer
                                      ? _accentColor
                                      : Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'EXIT',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _started = false;
                            _finished = false;
                          });
                          _startGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'PLAY AGAIN',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardEntry {
  final String name;
  final int score;
  _LeaderboardEntry(this.name, this.score);
}
