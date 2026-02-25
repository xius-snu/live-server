import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/paint_roller_game.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../models/house.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late PaintRollerGame _game;
  bool _roundComplete = false;
  double _lastPayout = 0;
  double _lastStreakBonus = 0;
  int _lastCoveragePercent = 0;
  bool _showPayoutAnim = false;
  int _payoutAnimKey = 0; // increments each payout to give TweenAnimationBuilder a stable key
  GameService? _gameService;

  // Slide transition for wall/house changes.
  // Uses fractional offsets (0.0–1.0) — fully scalable, no pixel math.
  late AnimationController _slideController;
  bool _slidingOut = true;
  VoidCallback? _pendingTransitionAction;

  /// Current fractional horizontal offset for sliding content.
  /// -1.0 = fully off-screen left, 0.0 = natural, +1.0 = fully off-screen right.
  double _slideFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _game = PaintRollerGame();
    _game.onRoundComplete = _onRoundComplete;
    _game.onStripePainted = _onStripePainted;

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _slideController.addListener(_onSlideUpdate);
    _slideController.addStatusListener(_onSlideStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameService = Provider.of<GameService>(context, listen: false);
      _gameService!.addListener(_onGameServiceChanged);
      _configureGame();
    });
  }

  @override
  void dispose() {
    _slideController.removeListener(_onSlideUpdate);
    _slideController.removeStatusListener(_onSlideStatus);
    _slideController.dispose();
    _gameService?.removeListener(_onGameServiceChanged);
    super.dispose();
  }

  void _onSlideUpdate() {
    final t = Curves.easeInOut.transform(_slideController.value);
    setState(() {
      if (_slidingOut) {
        _slideFraction = -t;           // 0 → -1 (slide left)
      } else {
        _slideFraction = 1.0 - t;      // +1 → 0 (slide in from right)
      }
    });
    // Sync wall slide in Flame (wall, border, stripes only)
    _game.wallSlide = _slideFraction;
  }

  void _onSlideStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _slidingOut) {
      // Midpoint: old content is fully off-screen left.
      // Swap game state while off-screen.
      _pendingTransitionAction?.call();
      _pendingTransitionAction = null;

      // IMPORTANT: set fraction to +1.0 NOW so the new content starts
      // off-screen right — prevents a gap frame at the old -1.0 position.
      _slidingOut = false;
      _slideFraction = 1.0;
      _game.wallSlide = 1.0;
      _slideController.reset();
      _slideController.forward();
    } else if (status == AnimationStatus.completed && !_slidingOut) {
      // Done — reset everything.
      setState(() {
        _slideFraction = 0.0;
      });
      _game.wallSlide = 0.0;
      _game.isTransitioning = false;
      _slidingOut = true;
      _slideController.reset();
    }
  }

  /// Start a slide transition, running [action] at the midpoint (off-screen).
  void _beginSlideTransition(VoidCallback action) {
    if (_slideController.isAnimating) return;
    _game.isTransitioning = true;
    _slidingOut = true;
    _pendingTransitionAction = action;
    _slideController.reset();
    _slideController.forward();
  }

  /// Called whenever GameService notifies (e.g. after purchasing an upgrade).
  /// Updates the roller live without resetting the current round.
  void _onGameServiceChanged() {
    if (_gameService == null || !_game.isMounted) return;
    _game.updateRollerSettings(
      rollerWidthFraction: _gameService!.rollerWidthPercent,
      rollerSpeedMultiplier: _gameService!.rollerSpeedMultiplier,
      maxStrokes: _gameService!.maxStrokes,
    );
    _game.setRollerSkin(_gameService!.equippedSkin);
    _game.setRollerPaintColor(_gameService!.equippedPaintColor);
  }

  void _configureGame() {
    final gameService = Provider.of<GameService>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    // Use the randomized visual house tier for wall appearance
    final visualHouse = gameService.visualHouseDef;
    final room = visualHouse.room;

    // House tier 0-6 based on visual type index
    final houseTier = visualHouse.typeIndex;
    final cycleLevel = gameService.visualCycleLevel;

    _game.configure(
      rollerWidthFraction: gameService.rollerWidthPercent,
      rollerSpeedMultiplier: gameService.rollerSpeedMultiplier,
      maxStrokes: gameService.maxStrokes,
      room: room,
      houseTier: houseTier,
      cycleLevel: cycleLevel,
      borderColor: visualHouse.borderColor,
      rollerPaintColor: gameService.equippedPaintColor,
    );

    // Sync equipped roller skin
    _game.setRollerSkin(gameService.equippedSkin);

    // Start background music (only starts once, safe to call repeatedly)
    audioService.startBgm();

    setState(() {
      _roundComplete = false;
      // Don't reset _showPayoutAnim here — let the Future.delayed in
      // _onRoundComplete handle it so the payout animation finishes smoothly
      // even while the wall slide transition is happening.
    });
  }

  void _onStripePainted() {
    HapticFeedback.lightImpact();
    final audioService = Provider.of<AudioService>(context, listen: false);
    audioService.playRollerSweep();
    setState(() {});
  }

  void _onRoundComplete(double coverage, int coveragePercent) {
    final gameService = Provider.of<GameService>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    final (payout, streakBonus) = gameService.completePaintRound(coverage);

    // Fire-and-forget leaderboard stat submission
    final lbService = Provider.of<LeaderboardService>(context, listen: false);
    lbService.submitRoundStats(coverage, payout + streakBonus);

    audioService.playRoundComplete(streak: gameService.streak);

    // Each house is one wall — auto-transition to next after payout.
    setState(() {
      _roundComplete = true;
      _lastPayout = payout;
      _lastStreakBonus = streakBonus;
      _lastCoveragePercent = coveragePercent;
      _showPayoutAnim = true;
      _payoutAnimKey++;
    });

    HapticFeedback.mediumImpact();

    // Brief pause to admire the finished wall, then slide to next
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _autoNextHouse();
    });

    // Hide payout overlay after its animation finishes
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showPayoutAnim = false);
      }
    });
  }

  void _autoNextHouse() {
    _beginSlideTransition(() {
      final gameService = Provider.of<GameService>(context, listen: false);
      gameService.nextHouseFree();
      _configureGame();
    });
  }

  /// Compute the wall rect in screen coords using the same logic as BackgroundComponent.
  Rect _computeWallRect(Size screenSize) {
    const imgAspect = 1080.0 / 2340.0;
    final screenAspect = screenSize.width / screenSize.height;

    double drawW, drawH, drawX, drawY;
    if (screenAspect < imgAspect) {
      drawW = screenSize.width;
      drawH = screenSize.width / imgAspect;
      drawX = 0;
      drawY = 0;
    } else {
      drawH = screenSize.height;
      drawW = screenSize.height * imgAspect;
      drawX = (screenSize.width - drawW) / 2;
      drawY = 0;
    }

    const wallTopFraction = 0.32;
    const wallBottomFraction = 0.72;

    final wallTop = drawY + drawH * wallTopFraction;
    final wallBottom = drawY + drawH * wallBottomFraction;
    return Rect.fromLTRB(drawX, wallTop, drawX + drawW, wallBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, _) {
        final house = gameService.currentHouseDef;
        final roundState = _game.isMounted ? _game.roundState : null;

        return LayoutBuilder(builder: (context, constraints) {
        final gameSize = Size(constraints.maxWidth, constraints.maxHeight);
        final wallRect = _computeWallRect(gameSize);
        // Actual game wall is 85% of bg wall width, centered (matches paint_roller_game.dart)
        // Actual game wall matches paint_roller_game.dart layout
        final gameWallWidth = (wallRect.width * 0.90).clamp(80.0, 420.0);
        final gameWallRight = wallRect.left + (wallRect.width + gameWallWidth) / 2;
        final gameWallTop = wallRect.top + wallRect.height * 0.03;
        final gameWallHeight = (wallRect.height * 0.88).clamp(80.0, 2000.0);
        final gameWallBottom = gameWallTop + gameWallHeight;

        return Stack(
          children: [
            // === Flame game: static widget, wall slides internally via wallSlide ===
            GameWidget(game: _game),

            // === House name + info, cat, stroke count — stays in place, no slide ===
            Positioned(
              top: wallRect.top - 56,
              left: 0,
              right: 0,
              child: Text(
                gameService.visualHouseDef.displayName(gameService.visualCycleLevel).toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2A2A2A),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // Cat sleeping on top-right corner of wall border (slides with wall)
            Positioned(
              top: wallRect.top - 22,
              left: gameWallRight - 100 + _slideFraction * gameSize.width,
              child: Image.asset(
                'assets/images/home/cat.png',
                width: 100,
                height: 75,
                fit: BoxFit.contain,
              ),
            ),

            // Stroke counter below game wall
            if (roundState != null)
              Positioned(
                top: gameWallBottom + 18,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${roundState.maxStrokes - roundState.strokesRemaining}/${roundState.maxStrokes}',
                    style: const TextStyle(
                      color: Color(0xFF2A2A2A),
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),

            // === Tap prompt (below the roller) ===
            if (!_roundComplete)
              Positioned(
                top: gameWallBottom + 190,
                left: 16,
                right: 16,
                child: _PulsingText(
                  text: 'TAP TO PAINT',
                  color: const Color(0xFF2A2A2A),
                ),
              ),

            // === PAYOUT ANIMATION + CONFETTI ===
            if (_showPayoutAnim) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: _ConfettiOverlay(key: ValueKey('confetti_$_lastCoveragePercent')),
                ),
              ),
              _buildPayoutAnimation(),
            ],
          ],
        );
        });
      },
    );
  }

  static String _formatWithCommas(double value) {
    final whole = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return buf.toString();
  }

  Widget _buildPayoutAnimation() {
    final coverage = _lastCoveragePercent / 100.0;
    final bonus = GameService.coverageBonus(coverage);
    final bonusLabel = bonus >= 3.0
        ? 'PERFECT 3x'
        : bonus >= 2.0
            ? 'GREAT 2x'
            : bonus >= 1.5
                ? 'NICE 1.5x'
                : null;

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.38,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('payout_$_payoutAnimKey'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        builder: (context, value, child) {
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
          child: Builder(builder: (_) {
            final hasBonus = bonusLabel != null;
            final bonusColor = bonus >= 3.0
                ? const Color(0xFFE53935) // red
                : bonus >= 2.0
                    ? const Color(0xFFF5C842) // gold
                    : const Color(0xFFB0BEC5); // silver
            final bonusTextColor = bonus >= 3.0
                ? Colors.white
                : const Color(0xFF2A2A2A);
            const radius = Radius.circular(22);
            const noRadius = Radius.zero;

            return IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bonus label (top part of unified card)
                  if (hasBonus)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: bonusColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: radius,
                          topRight: radius,
                          bottomLeft: noRadius,
                          bottomRight: noRadius,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          bonusLabel!,
                          style: TextStyle(
                            color: bonusTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  // Cash reward (bottom part of unified card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.78),
                      borderRadius: BorderRadius.only(
                        topLeft: hasBonus ? noRadius : radius,
                        topRight: hasBonus ? noRadius : radius,
                        bottomLeft: radius,
                        bottomRight: radius,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/UI/coin250.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${_formatWithCommas(_lastPayout + _lastStreakBonus)}',
                          style: const TextStyle(
                            color: Color(0xFFFFC843),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

}

// === Pulsing text widget for TAP TO PAINT ===
class _PulsingText extends StatefulWidget {
  final String text;
  final Color color;

  const _PulsingText({required this.text, required this.color});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final opacity = 0.5 + 0.5 * t;
        final yOffset = -2.0 + 4.0 * t;
        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

// === Confetti paint splat overlay on round complete ===
class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({super.key});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final _rng = Random();

  static const _colors = [
    Color(0xFFE94560),
    Color(0xFF4ADE80),
    Color(0xFFF5C842),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFFFF6B6B),
    Color(0xFF38BDF8),
  ];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(25, (_) {
      return _ConfettiParticle(
        x: 0.3 + _rng.nextDouble() * 0.4, // center-ish
        y: 0.3 + _rng.nextDouble() * 0.1,
        vx: (_rng.nextDouble() - 0.5) * 300,
        vy: -150 - _rng.nextDouble() * 250,
        rotation: _rng.nextDouble() * 6.28,
        rotSpeed: (_rng.nextDouble() - 0.5) * 8,
        color: _colors[_rng.nextInt(_colors.length)],
        size: 4 + _rng.nextDouble() * 6,
        isCircle: _rng.nextBool(),
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiParticle {
  double x, y, vx, vy, rotation, rotSpeed;
  final Color color;
  final double size;
  final bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotSpeed,
    required this.color,
    required this.size,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  static const gravity = 500.0;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final fadeOut = t > 0.6 ? 1.0 - (t - 0.6) / 0.4 : 1.0;

    for (final p in particles) {
      final px = p.x * size.width + p.vx * t;
      final py = p.y * size.height + p.vy * t + 0.5 * gravity * t * t;
      final rot = p.rotation + p.rotSpeed * t;

      if (py > size.height + 20) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      final paint = Paint()..color = p.color.withOpacity((fadeOut * 0.85).clamp(0.0, 1.0));

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
