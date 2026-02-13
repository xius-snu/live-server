import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/paint_roller_game.dart';
import '../services/game_service.dart';
import '../models/house.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PaintRollerGame _game;
  bool _roundComplete = false;
  double _lastPayout = 0;
  int _lastCoveragePercent = 0;
  bool _showPayoutAnim = false;
  bool _prestigeAvailable = false;

  @override
  void initState() {
    super.initState();
    _game = PaintRollerGame();
    _game.onRoundComplete = _onRoundComplete;
    _game.onStripePainted = _onStripePainted;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureGame();
    });
  }

  void _configureGame() {
    final gameService = Provider.of<GameService>(context, listen: false);
    final room = gameService.currentRoomDef;

    _game.configure(
      rollerWidthFraction: gameService.rollerWidthPercent,
      rollerSpeedMultiplier: gameService.rollerSpeedMultiplier,
      maxStrokes: gameService.maxStrokes,
      room: room,
    );
    setState(() {
      _roundComplete = false;
      _showPayoutAnim = false;
      _prestigeAvailable = false;
    });
  }

  void _onStripePainted() {
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _onRoundComplete(double coverage, int coveragePercent) {
    final gameService = Provider.of<GameService>(context, listen: false);
    final payout = gameService.completePaintRound(coverage);

    setState(() {
      _roundComplete = true;
      _lastPayout = payout;
      _lastCoveragePercent = coveragePercent;
      _showPayoutAnim = true;
    });

    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showPayoutAnim = false);
      }
    });
  }

  void _nextWall() {
    final gameService = Provider.of<GameService>(context, listen: false);
    final canPrestige = gameService.advanceRoom();

    if (canPrestige) {
      setState(() => _prestigeAvailable = true);
    } else {
      _configureGame();
    }
  }

  void _doPrestige() {
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.prestige();
    _configureGame();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, _) {
        final house = gameService.currentHouseDef;
        final room = house.rooms[gameService.currentRoom];
        final roundState = _game.isMounted ? _game.roundState : null;

        return Stack(
          children: [
            // Flame game
            GameWidget(game: _game),

            // Top HUD - Room info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF1A1A2E).withOpacity(0),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Text(
                        '${house.icon} ${house.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Text(' — ', style: TextStyle(color: Colors.white38)),
                      Text(
                        room.name,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Room ${gameService.currentRoom + 1}/5',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom HUD
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF1A1A2E).withOpacity(0.9),
                      const Color(0xFF1A1A2E).withOpacity(0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Coverage bar
                    if (roundState != null) ...[
                      Row(
                        children: [
                          Text(
                            'Coverage',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: roundState.coveragePercent,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  _getCoverageColor(roundState.coveragePercent),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(roundState.coveragePercent * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: _getCoverageColor(roundState.coveragePercent),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Stroke indicators
                    if (!_roundComplete && roundState != null)
                      _buildStrokeIndicators(roundState),

                    // Tap prompt
                    if (!_roundComplete)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'TAP TO PAINT',
                          style: TextStyle(
                            color: const Color(0xFFE94560).withOpacity(0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                    // Round complete actions
                    if (_roundComplete && !_prestigeAvailable)
                      _buildRoundComplete(),

                    if (_prestigeAvailable)
                      _buildPrestigePrompt(gameService),
                  ],
                ),
              ),
            ),

            // Payout animation
            if (_showPayoutAnim)
              _buildPayoutAnimation(),
          ],
        );
      },
    );
  }

  Widget _buildStrokeIndicators(dynamic roundState) {
    final max = roundState.maxStrokes as int;
    final remaining = roundState.strokesRemaining as int;
    final used = max - remaining;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Strokes: ',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        ...List.generate(max, (i) {
          return Container(
            width: 24,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i < used
                  ? const Color(0xFF4ADE80)
                  : Colors.white.withOpacity(0.15),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '$remaining left',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRoundComplete() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getCoverageColor(_lastCoveragePercent / 100).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getCoverageColor(_lastCoveragePercent / 100).withOpacity(0.4)),
          ),
          child: Text(
            '$_lastCoveragePercent% coverage',
            style: TextStyle(
              color: _getCoverageColor(_lastCoveragePercent / 100),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextWall,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'NEXT WALL',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrestigePrompt(GameService gameService) {
    final nextTier = HouseDefinition.nextTier(gameService.currentHouse);
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF5C842).withOpacity(0.15),
                const Color(0xFFE94560).withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'HOUSE COMPLETE!',
                style: TextStyle(
                  color: Color(0xFFF5C842),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextTier != null
                    ? 'Move to ${HouseDefinition.getDefinition(nextTier).name} — bigger walls!'
                    : 'Prestige for another star!',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Earn 1 star (+10% cash). Walls get bigger — upgrade to keep up!',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _doPrestige,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C842),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'PRESTIGE NOW',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutAnimation() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        builder: (context, value, child) {
          // Clamp opacity to valid range [0.0, 1.0]
          double opacity;
          if (value < 0.6) {
            opacity = 1.0;
          } else {
            opacity = (1.0 - (value - 0.6) / 0.4).clamp(0.0, 1.0);
          }
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, -50 * value),
              child: child,
            ),
          );
        },
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF4ADE80).withOpacity(0.3),
              ),
            ),
            child: Text(
              '+\$${_lastPayout.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCoverageColor(double coverage) {
    if (coverage >= 0.95) return const Color(0xFFF5C842);
    if (coverage >= 0.90) return const Color(0xFF4ADE80);
    if (coverage >= 0.70) return const Color(0xFF3B82F6);
    return Colors.white54;
  }
}
