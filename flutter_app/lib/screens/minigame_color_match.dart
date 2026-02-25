import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ColorMatchMinigame extends StatefulWidget {
  const ColorMatchMinigame({super.key});

  @override
  State<ColorMatchMinigame> createState() => _ColorMatchMinigameState();
}

class _ColorMatchMinigameState extends State<ColorMatchMinigame>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFFA855F7);
  static const _bgColor = Color(0xFF1A1A2E);
  static const _startingColors = 3;
  static const _maxColors = 8;

  final _random = Random();

  // Available palette colors
  static const _palette = [
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
  ];

  static const _paletteNames = [
    'Red',
    'Blue',
    'Green',
    'Amber',
    'Purple',
    'Pink',
  ];

  // Game states
  bool _started = false;
  bool _finished = false;

  // Round state
  int _currentRound = 1;
  int _sequenceLength = _startingColors;
  List<int> _sequence = [];
  List<int> _playerInput = [];
  bool _showingSequence = false;
  int _showingIndex = -1;
  bool _waitingForInput = false;
  bool _showingResult = false;
  bool _roundCorrect = false;
  Timer? _sequenceTimer;

  // Scoring
  int _highestRound = 0;
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
    _sequenceTimer?.cancel();
    super.dispose();
  }

  List<_LeaderboardEntry> _generateFakeLeaderboard() {
    return [
      _LeaderboardEntry('MemoryMaster', 8),
      _LeaderboardEntry('ColorGenius', 7),
      _LeaderboardEntry('PaintPro', 6),
      _LeaderboardEntry('RainbowKing', 5),
      _LeaderboardEntry('PatternWiz', 4),
    ];
  }

  void _startGame() {
    setState(() {
      _started = true;
      _finished = false;
      _currentRound = 1;
      _sequenceLength = _startingColors;
      _highestRound = 0;
    });
    _startRound();
  }

  void _startRound() {
    // Generate random sequence
    _sequence = List.generate(
      _sequenceLength,
      (_) => _random.nextInt(_palette.length),
    );
    _playerInput = [];
    _waitingForInput = false;
    _showingResult = false;

    setState(() {
      _showingSequence = true;
      _showingIndex = -1;
    });

    // Show each color one at a time
    int index = 0;
    _sequenceTimer?.cancel();

    // Brief pause before showing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _sequenceTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (index < _sequence.length) {
          setState(() {
            _showingIndex = index;
          });
          index++;
        } else {
          timer.cancel();
          // Brief pause after showing all, then hide
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            setState(() {
              _showingSequence = false;
              _showingIndex = -1;
              _waitingForInput = true;
            });
          });
        }
      });
    });
  }

  void _onColorTap(int colorIndex) {
    if (!_waitingForInput || _showingResult) return;

    setState(() {
      _playerInput.add(colorIndex);
    });

    final currentPos = _playerInput.length - 1;

    // Check if this input is correct
    if (_playerInput[currentPos] != _sequence[currentPos]) {
      // Wrong answer - game over
      _waitingForInput = false;
      setState(() {
        _showingResult = true;
        _roundCorrect = false;
        _highestRound = _currentRound - 1;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _endGame();
      });
      return;
    }

    // Check if sequence is complete
    if (_playerInput.length == _sequence.length) {
      // Correct!
      _waitingForInput = false;
      setState(() {
        _showingResult = true;
        _roundCorrect = true;
        _highestRound = _currentRound;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _currentRound++;
          _sequenceLength = (_startingColors + _currentRound - 1).clamp(
            _startingColors,
            _maxColors,
          );
          _showingResult = false;
        });
        _startRound();
      });
    }
  }

  void _endGame() {
    _sequenceTimer?.cancel();
    setState(() {
      _finished = true;
      if (_highestRound > _personalBest) {
        _personalBest = _highestRound;
      }
      _leaderboard = _generateFakeLeaderboard();
      _leaderboard.add(_LeaderboardEntry('You', _highestRound));
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
              _sequenceTimer?.cancel();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          const Text(
            'Color Match',
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
                'Round $_currentRound',
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
          const Icon(Icons.palette, size: 80, color: _accentColor),
          const SizedBox(height: 20),
          const Text(
            'Color Match',
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
              'Memorize the color sequence, then tap them in the correct order!\nStarts with 3 colors, adds 1 each round.',
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
              'Personal Best: Round $_personalBest',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Status text
          Text(
            _showingSequence
                ? 'MEMORIZE!'
                : _waitingForInput
                    ? 'Your turn! Tap the colors in order.'
                    : _showingResult
                        ? (_roundCorrect ? 'CORRECT!' : 'WRONG!')
                        : 'Get ready...',
            style: TextStyle(
              color: _showingResult
                  ? (_roundCorrect ? Colors.greenAccent : Colors.redAccent)
                  : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sequence: $_sequenceLength colors',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          // Sequence display area
          Container(
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accentColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _showingSequence
                ? _buildSequenceDisplay()
                : _waitingForInput || _showingResult
                    ? _buildPlayerInputDisplay()
                    : const Center(
                        child: Text(
                          '...',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 32,
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 12),
          // Progress dots
          if (_waitingForInput || _showingResult) _buildProgressDots(),
          const Spacer(),
          // Color palette
          if (_waitingForInput) _buildColorPalette(),
          if (_showingSequence)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                'Watch carefully...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSequenceDisplay() {
    if (_showingIndex < 0 || _showingIndex >= _sequence.length) {
      return const Center(
        child: Text(
          'Watch...',
          style: TextStyle(color: Colors.white38, fontSize: 18),
        ),
      );
    }

    final colorIndex = _sequence[_showingIndex];
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: _palette[colorIndex],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _palette[colorIndex].withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${_showingIndex + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInputDisplay() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_playerInput.length, (i) {
            final colorIndex = _playerInput[i];
            final isCorrect = i < _sequence.length &&
                _playerInput[i] == _sequence[i];
            return Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _palette[colorIndex],
                shape: BoxShape.circle,
                border: _showingResult
                    ? Border.all(
                        color: isCorrect
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        width: 3,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: _palette[colorIndex].withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_sequence.length, (i) {
          final filled = i < _playerInput.length;
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: filled
                  ? _accentColor
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(_palette.length, (i) {
          return GestureDetector(
            onTap: () => _onColorTap(i),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _palette[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _palette[i].withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _paletteNames[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResultsOverlay() {
    String rewardText;
    IconData rewardIcon;
    Color rewardColor;
    if (_highestRound >= 6) {
      rewardText = 'Legendary Paint Can';
      rewardIcon = Icons.auto_awesome;
      rewardColor = Colors.amber;
    } else if (_highestRound >= 4) {
      rewardText = 'Rare Paint Can';
      rewardIcon = Icons.star;
      rewardColor = Colors.purpleAccent;
    } else if (_highestRound >= 2) {
      rewardText = 'Common Paint Can';
      rewardIcon = Icons.inventory_2;
      rewardColor = Colors.lightBlueAccent;
    } else {
      rewardText = 'Practice Token';
      rewardIcon = Icons.refresh;
      rewardColor = Colors.grey;
    }

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
                  'GAME OVER',
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
                        '$_highestRound',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Rounds Completed',
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
                  'Personal Best: Round $_personalBest',
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
                    color: rewardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rewardIcon, color: rewardColor),
                      const SizedBox(width: 6),
                      Text(
                        rewardText,
                        style: TextStyle(
                          color: rewardColor,
                          fontSize: 18,
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
                                'Rd ${entry.score}',
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
