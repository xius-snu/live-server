import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/shapes.dart';
import '../services/accuracy_scorer.dart';
import '../services/user_service.dart';

/// Variable ratio event types
enum SpecialEvent {
  none,
  hotStreak,    // 3+ consecutive wins
  luckyDraw,    // Random 10% - double drop
  bonusRound,   // Random 5% - guaranteed high-tier
  nearMiss,     // 60-69% score - streak preserved
  mysteryReveal, // Every 10th success
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> with SingleTickerProviderStateMixin {
  // Game State
  final List<Offset> _currentPath = [];
  String _targetShapeName = 'Circle'; // Default
  bool _isDrawing = false;
  double? _accuracyScore;
  bool _lastAttemptSuccess = false;
  String? _earnedRarity;

  // Variable Ratio Event State
  SpecialEvent _currentEvent = SpecialEvent.none;
  bool _isMysteryReveal = false;
  bool _showMysteryAnimation = false;
  int _localSuccessCount = 0; // Track for mystery reveal timing
  List<String> _bonusItems = []; // For double drops

  // Visual Guide
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  Color _guideColor = Colors.cyanAccent;

  // Key to get actual canvas size (important for scoring accuracy)
  final GlobalKey _canvasKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _pickNewShape();
    _feedbackController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _feedbackAnimation = CurvedAnimation(
        parent: _feedbackController, curve: Curves.easeOutBack);
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _pickNewShape() {
    final userService = Provider.of<UserService>(context, listen: false);
    final random = Random();

    // Create progression state
    final progression = PlayerProgression(
      collectedShapes: userService.collectedShapes,
      affinityTier: userService.affinityTier,
    );

    // Check for special events
    _currentEvent = SpecialEvent.none;
    _bonusItems.clear();

    // Hot Streak: 3+ consecutive wins
    if (userService.streakCount >= 3) {
      _currentEvent = SpecialEvent.hotStreak;
    }

    // Random events (only if not already in hot streak)
    if (_currentEvent == SpecialEvent.none) {
      final roll = random.nextDouble();
      if (roll < 0.05) {
        // 5% Bonus Round
        _currentEvent = SpecialEvent.bonusRound;
      } else if (roll < 0.15) {
        // 10% Lucky Draw
        _currentEvent = SpecialEvent.luckyDraw;
      }
    }

    // Mystery Reveal every 10th success
    _isMysteryReveal = (_localSuccessCount + 1) % 10 == 0 && _localSuccessCount > 0;

    // Select shape based on event
    String newShape;
    if (_currentEvent == SpecialEvent.bonusRound) {
      newShape = ShapeRegistry.getHighTierShape();
    } else if (_currentEvent == SpecialEvent.hotStreak) {
      // Hot streak gives non-affinity shape
      newShape = ShapeRegistry.getNonAffinityShape(progression);
    } else {
      newShape = ShapeRegistry.getWeightedRandomShape(progression);
    }

    setState(() {
      _targetShapeName = newShape;
      _currentPath.clear();
      _accuracyScore = null;
      _showMysteryAnimation = false;
      _guideColor = ShapeRegistry.getColorForShape(_targetShapeName);
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentPath.clear();
      _accuracyScore = null;
      _addPoint(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _addPoint(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
    });
    _evaluateDrawing();
  }

  void _addPoint(Offset p) {
    _currentPath.add(p);
  }

  void _evaluateDrawing() async {
    if (_currentPath.length < 10) {
      // Too short, just reset
      _resetRound();
      return;
    }

    // Get actual canvas size from RenderBox (accounts for bottom nav, etc.)
    final RenderBox? renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      _resetRound();
      return;
    }
    final canvasSize = renderBox.size;
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final guideSize = min(canvasSize.width, canvasSize.height) * 0.54;

    // Get target shape and convert to screen coordinates
    final shapeDef = ShapeRegistry.get(_targetShapeName);
    if (shapeDef == null) {
      _resetRound();
      return;
    }

    final targetPoints = shapeDef.toScreenPath(center, guideSize);
    final result = AccuracyScorer.score(
      userPoints: _currentPath,
      targetPoints: targetPoints,
      guideSize: guideSize,
    );
    final score = result.combined;
    print('DEBUG: Shape=$_targetShapeName, Score=$score, Coverage=${result.coverage}, Precision=${result.precision}, Points=${_currentPath.length}');

    setState(() {
      _accuracyScore = score;
    });

    final userService = Provider.of<UserService>(context, listen: false);

    if (score >= 0.70) {
      // Success!
      _localSuccessCount++;
      userService.incrementStreak();

      final rarity = _determineRarity();

      // Handle Lucky Draw (double drop)
      if (_currentEvent == SpecialEvent.luckyDraw) {
        final secondRarity = _determineRarity();
        _awardItem(_targetShapeName, rarity);
        _awardItem(_targetShapeName, secondRarity);
        _bonusItems = ['$rarity $_targetShapeName', '$secondRarity $_targetShapeName'];
      } else {
        _awardItem(_targetShapeName, rarity);
      }

      // Handle Mystery Reveal
      if (_isMysteryReveal) {
        setState(() {
          _lastAttemptSuccess = true;
          _earnedRarity = rarity;
          _showMysteryAnimation = true;
        });
        HapticFeedback.heavyImpact();
        _feedbackController.forward(from: 0.0);

        // Longer delay for mystery reveal animation
        Timer(const Duration(milliseconds: 2500), () {
          _pickNewShape();
          _feedbackController.reset();
        });
      } else {
        setState(() {
          _lastAttemptSuccess = true;
          _earnedRarity = rarity;
        });
        HapticFeedback.mediumImpact();
        _feedbackController.forward(from: 0.0);

        Timer(const Duration(milliseconds: 1500), () {
          _pickNewShape();
          _feedbackController.reset();
        });
      }
    } else if (score >= 0.60) {
      // Near Miss (60-69%) - preserve streak!
      setState(() {
        _lastAttemptSuccess = false;
        _earnedRarity = null;
        _currentEvent = SpecialEvent.nearMiss;
      });
      userService.preserveStreak();
      HapticFeedback.lightImpact();
      _feedbackController.forward(from: 0.0);

      Timer(const Duration(milliseconds: 1500), () {
        _pickNewShape();
        _feedbackController.reset();
      });
    } else {
      // Fail - reset streak
      setState(() {
        _lastAttemptSuccess = false;
        _earnedRarity = null;
      });
      userService.resetStreak();
      _feedbackController.forward(from: 0.0);

      Timer(const Duration(milliseconds: 1200), () {
        _pickNewShape();
        _feedbackController.reset();
      });
    }
  }

  void _resetRound() {
    setState(() {
      _currentPath.clear();
      _accuracyScore = null;
    });
  }

  String _determineRarity() {
    final r = Random().nextDouble();
    if (r < 0.5) return 'Common';
    if (r < 0.8) return 'Rare';
    if (r < 0.95) return 'Epic';
    return 'Legendary';
  }

  Future<void> _awardItem(String shape, String rarity) async {
    final userService = Provider.of<UserService>(context, listen: false);
    await userService.addInventoryItem(shape, rarity);
    // Silent success or maybe a toast in future
    // debugPrint("Awarded $rarity $shape");
  }

  String _getEventMessage() {
    switch (_currentEvent) {
      case SpecialEvent.hotStreak:
        return "YOU'RE ON FIRE!";
      case SpecialEvent.luckyDraw:
        return "LUCKY DRAW - 2x ITEMS!";
      case SpecialEvent.bonusRound:
        return "BONUS ROUND!";
      case SpecialEvent.nearMiss:
        return "SO CLOSE!";
      case SpecialEvent.mysteryReveal:
        return "MYSTERY REVEAL!";
      default:
        return "";
    }
  }

  Color _getEventColor() {
    switch (_currentEvent) {
      case SpecialEvent.hotStreak:
        return Colors.orangeAccent;
      case SpecialEvent.luckyDraw:
        return Colors.purpleAccent;
      case SpecialEvent.bonusRound:
        return Colors.amberAccent;
      case SpecialEvent.nearMiss:
        return Colors.yellowAccent;
      case SpecialEvent.mysteryReveal:
        return Colors.pinkAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final streakCount = userService.streakCount;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. The Canvas Area
          Positioned.fill(
            child: GestureDetector(
              key: _canvasKey,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: GamePainter(
                  userPath: List.from(_currentPath),
                  targetShape: _targetShapeName,
                  guideColor: _guideColor,
                ),
              ),
            ),
          ),

          // 2. Header / Prompt
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Special Event Banner
                if (_currentEvent != SpecialEvent.none && _accuracyScore == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getEventColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getEventColor(), width: 2),
                    ),
                    child: Text(
                      _getEventMessage(),
                      style: TextStyle(
                        color: _getEventColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                // Shape Name
                Text(
                  _isMysteryReveal && _accuracyScore == null ? "???" : _targetShapeName.toUpperCase(),
                  style: TextStyle(
                    color: _guideColor.withOpacity(0.8),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // 3. Streak Counter (Top Left)
          if (streakCount > 0)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: streakCount >= 3
                      ? Colors.orangeAccent.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: streakCount >= 3 ? Colors.orangeAccent : Colors.white24,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      streakCount >= 3 ? Icons.local_fire_department : Icons.bolt,
                      color: streakCount >= 3 ? Colors.orangeAccent : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streakCount',
                      style: TextStyle(
                        color: streakCount >= 3 ? Colors.orangeAccent : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Feedback Overlay (Success or Fail)
          if (_accuracyScore != null)
            Positioned.fill(
              child: Center(
                child: ScaleTransition(
                  scale: _feedbackAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _lastAttemptSuccess
                            ? _guideColor
                            : (_currentEvent == SpecialEvent.nearMiss
                                ? Colors.yellowAccent
                                : Colors.redAccent),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_lastAttemptSuccess
                                  ? _guideColor
                                  : (_currentEvent == SpecialEvent.nearMiss
                                      ? Colors.yellowAccent
                                      : Colors.redAccent))
                              .withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mystery Reveal Animation
                        if (_showMysteryAnimation) ...[
                          const Text(
                            "MYSTERY REVEAL!",
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Icon(
                          _lastAttemptSuccess
                              ? Icons.check_circle_outline
                              : (_currentEvent == SpecialEvent.nearMiss
                                  ? Icons.trending_up
                                  : Icons.close_rounded),
                          color: _lastAttemptSuccess
                              ? _guideColor
                              : (_currentEvent == SpecialEvent.nearMiss
                                  ? Colors.yellowAccent
                                  : Colors.redAccent),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _lastAttemptSuccess
                              ? "ACQUIRED"
                              : (_currentEvent == SpecialEvent.nearMiss
                                  ? "SO CLOSE!"
                                  : "MISSED"),
                          style: TextStyle(
                            color: _lastAttemptSuccess
                                ? _guideColor
                                : (_currentEvent == SpecialEvent.nearMiss
                                    ? Colors.yellowAccent
                                    : Colors.redAccent),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        if (_lastAttemptSuccess) ...[
                          const SizedBox(height: 8),
                          // Lucky Draw shows both items
                          if (_bonusItems.isNotEmpty)
                            Column(
                              children: [
                                const Text(
                                  "DOUBLE DROP!",
                                  style: TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ..._bonusItems.map((item) => Text(
                                      item,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )),
                              ],
                            )
                          else
                            Text(
                              "$_earnedRarity $_targetShapeName",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                        if (_currentEvent == SpecialEvent.nearMiss) ...[
                          const SizedBox(height: 8),
                          const Text(
                            "Streak preserved!",
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          "Score: ${(_accuracyScore! * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: (_lastAttemptSuccess
                                    ? _guideColor
                                    : (_currentEvent == SpecialEvent.nearMiss
                                        ? Colors.yellowAccent
                                        : Colors.redAccent))
                                .withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Instructions / Status (Subtle)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  _isDrawing ? "Drawing..." : "Trace in one motion",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final List<Offset> userPath;
  final String targetShape;
  final Color guideColor;

  GamePainter({
    required this.userPath,
    required this.targetShape,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Scale guide based on screen width
    final guideSize = min(size.width, size.height) * 0.54;

    // 1. Draw Guide (The "Target")
    _drawGuide(canvas, center, guideSize);

    // 2. Draw User Path
    final Paint userPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0;

    if (userPath.isNotEmpty) {
      final path = Path();
      path.moveTo(userPath[0].dx, userPath[0].dy);
      for (int i = 1; i < userPath.length; i++) {
        path.lineTo(userPath[i].dx, userPath[i].dy);
      }
      canvas.drawPath(path, userPaint);
    }
  }

  void _drawGuide(Canvas canvas, Offset center, double width) {
    final Paint guidePaint = Paint()
      ..color = guideColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25.0
      ..strokeCap = StrokeCap.round;

    final Paint corePaint = Paint()
        ..color = guideColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

    final shapeDef = ShapeRegistry.get(targetShape);
    if (shapeDef == null) return;

    final path = shapeDef.toFlutterPath(center, width);

    // Shadow/Glow effect
    canvas.drawPath(path, guidePaint);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.userPath != userPath ||
           oldDelegate.targetShape != targetShape ||
           oldDelegate.guideColor != guideColor;
  }
}
