import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BullseyeMinigame extends StatefulWidget {
  const BullseyeMinigame({super.key});

  @override
  State<BullseyeMinigame> createState() => _BullseyeMinigameState();
}

class _BullseyeMinigameState extends State<BullseyeMinigame>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFF3B82F6);
  static const _bgColor = Color(0xFF1A1A2E);
  static const _totalRounds = 5;

  final _random = Random();

  // Game states
  bool _started = false;
  bool _finished = false;

  // Round state
  int _currentRound = 0;
  int _targetPercent = 50;
  double _barProgress = 0.0;
  bool _barMoving = false;
  bool _showingRoundResult = false;
  double _barSpeed = 0.0;
  Timer? _barTimer;

  // Scoring
  List<int> _roundScores = [];
  List<int> _roundTargets = [];
  List<int> _roundActuals = [];
  int _totalScore = 0;
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
    _barTimer?.cancel();
    super.dispose();
  }

  List<_LeaderboardEntry> _generateFakeLeaderboard() {
    return [
      _LeaderboardEntry('SniperPaint', 472),
      _LeaderboardEntry('PrecisionPro', 445),
      _LeaderboardEntry('BullseyeBoss', 420),
      _LeaderboardEntry('SharpShooter', 398),
      _LeaderboardEntry('AccuratePainter', 375),
    ];
  }

  void _startGame() {
    setState(() {
      _started = true;
      _finished = false;
      _currentRound = 0;
      _roundScores = [];
      _roundTargets = [];
      _roundActuals = [];
      _totalScore = 0;
    });
    _startRound();
  }

  void _startRound() {
    setState(() {
      _targetPercent = 40 + _random.nextInt(51); // 40-90
      _barProgress = 0.0;
      _barMoving = true;
      _showingRoundResult = false;
      // Speed varies: gets faster in later rounds
      _barSpeed = 0.004 + _random.nextDouble() * 0.003 + (_currentRound * 0.001);
    });

    _barTimer?.cancel();
    _barTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        _barProgress += _barSpeed;
        if (_barProgress >= 1.0) {
          _barProgress = 0.0; // wrap around
        }
      });
    });
  }

  void _stopBar() {
    if (!_barMoving) return;

    _barTimer?.cancel();
    final actualPercent = (_barProgress * 100).round();
    final accuracy = 100 - (actualPercent - _targetPercent).abs();
    final roundScore = accuracy.clamp(0, 100);

    setState(() {
      _barMoving = false;
      _showingRoundResult = true;
      _roundScores.add(roundScore);
      _roundTargets.add(_targetPercent);
      _roundActuals.add(actualPercent);
      _totalScore += roundScore;
    });

    // Move to next round or finish after delay
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _currentRound++;
      });
      if (_currentRound >= _totalRounds) {
        _endGame();
      } else {
        _startRound();
      }
    });
  }

  void _endGame() {
    setState(() {
      _finished = true;
      _barMoving = false;
      if (_totalScore > _personalBest) {
        _personalBest = _totalScore;
      }
      _leaderboard = _generateFakeLeaderboard();
      _leaderboard.add(_LeaderboardEntry('You', _totalScore));
      _leaderboard.sort((a, b) => b.score.compareTo(a.score));
      if (_leaderboard.length > 6) {
        _leaderboard = _leaderboard.sublist(0, 6);
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
            Column(
              children: [
                _buildHeader(),
                if (!_started && !_finished) _buildStartScreen(),
                if (_started && !_finished) Expanded(child: _buildGameplay()),
              ],
            ),
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
            onPressed: () {
              _barTimer?.cancel();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          const Text(
            'Bullseye',
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
                color: _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accentColor, width: 2),
              ),
              child: Text(
                'Round ${_currentRound + 1}/$_totalRounds',
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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
          const Icon(Icons.gps_fixed, size: 80, color: _accentColor),
          const SizedBox(height: 20),
          const Text(
            'Bullseye',
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
              'Hit the exact target percentage!\nStop the bar as close to the target as possible.',
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
              'Personal Best: $_personalBest pts',
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
    final actualPercent = (_barProgress * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Target display
          Text(
            'Hit exactly $_targetPercent%!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          // Current score display
          if (_roundScores.isNotEmpty)
            Text(
              'Score so far: $_totalScore',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 40),
          // Progress bar with target marker
          SizedBox(
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background bar
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _accentColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                // Fill bar
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 40,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _barProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _accentColor.withOpacity(0.6),
                                _accentColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Target marker
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final markerX =
                          constraints.maxWidth * (_targetPercent / 100.0);
                      return Stack(
                        children: [
                          Positioned(
                            left: markerX - 1.5,
                            top: 6,
                            child: Container(
                              width: 3,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.yellowAccent,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.yellowAccent.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: markerX - 16,
                            top: -2,
                            child: Text(
                              '$_targetPercent%',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Current percentage
          Text(
            '$actualPercent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 30),
          // Stop button or round result
          if (_barMoving)
            SizedBox(
              width: 200,
              height: 64,
              child: ElevatedButton(
                onPressed: _stopBar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'STOP!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (_showingRoundResult && _roundScores.isNotEmpty) ...[
            _buildRoundResult(),
          ],
          const Spacer(),
          // Previous rounds summary
          if (_roundScores.isNotEmpty) _buildRoundsSummary(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRoundResult() {
    final lastScore = _roundScores.last;
    final lastTarget = _roundTargets.last;
    final lastActual = _roundActuals.last;
    final diff = (lastActual - lastTarget).abs();

    Color resultColor;
    String resultText;
    if (diff == 0) {
      resultColor = Colors.greenAccent;
      resultText = 'PERFECT!';
    } else if (diff <= 3) {
      resultColor = Colors.greenAccent;
      resultText = 'AMAZING!';
    } else if (diff <= 8) {
      resultColor = Colors.yellowAccent;
      resultText = 'GREAT!';
    } else if (diff <= 15) {
      resultColor = Colors.orange;
      resultText = 'GOOD';
    } else {
      resultColor = Colors.redAccent;
      resultText = 'MISS';
    }

    return Column(
      children: [
        Text(
          resultText,
          style: TextStyle(
            color: resultColor,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Target: $lastTarget% | Yours: $lastActual% | +$lastScore pts',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRoundsSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_totalRounds, (i) {
          if (i < _roundScores.length) {
            final score = _roundScores[i];
            Color dotColor;
            if (score >= 95) {
              dotColor = Colors.greenAccent;
            } else if (score >= 80) {
              dotColor = Colors.yellowAccent;
            } else if (score >= 60) {
              dotColor = Colors.orange;
            } else {
              dotColor = Colors.redAccent;
            }
            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        color: dotColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'R${i + 1}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'R${i + 1}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 10,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildResultsOverlay() {
    final avgAccuracy = _totalScore ~/ _totalRounds;
    final gems = (_totalScore / 100).ceil();

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
                  'RESULTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                // Total score
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_totalScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Total Accuracy ($avgAccuracy% avg)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Round breakdown
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: List.generate(_totalRounds, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              'Round ${i + 1}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Target: ${_roundTargets[i]}%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hit: ${_roundActuals[i]}%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '+${_roundScores[i]}',
                              style: const TextStyle(
                                color: _accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                // Personal best
                Text(
                  'Personal Best: $_personalBest',
                  style: const TextStyle(
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
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond, color: Colors.purpleAccent),
                      const SizedBox(width: 6),
                      Text(
                        '+$gems Gems',
                        style: const TextStyle(
                          color: Colors.purpleAccent,
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
                                '${entry.score} pts',
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
