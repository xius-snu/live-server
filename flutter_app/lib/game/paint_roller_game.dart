import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'components/wall_component.dart';
import 'components/roller_component.dart';
import 'components/paint_stripe_component.dart';
import 'components/paint_splat_particle.dart';
import 'components/floating_coverage_text.dart';
import 'components/perfect_shimmer_component.dart';
import 'components/background_component.dart';
import 'components/wall_border_component.dart';
import 'components/wall_pattern_overlay.dart';
import '../models/house.dart';
class PaintRollerGame extends FlameGame with TapCallbacks {
  late BackgroundComponent background;
  late WallComponent wall;
  late WallBorderComponent wallBorder;
  late WallPatternOverlay patternOverlay;
  late RollerComponent roller;
  late GameRoundState roundState;

  // Callback for when round ends
  void Function(double coverage, int bonus)? onRoundComplete;
  // Callback for when a stripe is painted
  void Function()? onStripePainted;

  // Block taps during house/wall transition animation
  bool isTransitioning = false;

  /// Fractional horizontal slide for wall content only.
  /// 0.0 = natural position, -1.0 = one screen-width left, +1.0 = right.
  /// Applied every frame as absolute offset — no delta accumulation.
  double wallSlide = 0.0;

  // Config from upgrades
  double _rollerWidthFraction = 0.15; // base 15% of wall per stroke
  double _rollerSpeedMultiplier = 1.0;
  int _maxStrokes = 6;
  Color _wallColor = const Color(0xFFE8DCC8);
  Color _dirtColor = const Color(0xFFC4A882);

  // Paint color comes from the equipped roller skin.
  Color _rollerPaintColor = const Color(0xFFFF3B30); // default roller: bright red
  BlendMode _rollerPaintBlendMode = BlendMode.srcOver;

  // Seed counter so wall patterns vary each round.
  int _wallSeedCounter = 0;

  // Reference width ensures difficulty is identical across all screen sizes.
  static const double _referenceWidth = 400.0;

  double get _wallWidth {
    final bgWallRect = background.getWallRect();
    final maxWallW = _referenceWidth;
    return (bgWallRect.width * 0.90).clamp(80.0, maxWallW);
  }

  double get _wallHeight {
    final bgWallRect = background.getWallRect();
    return (bgWallRect.height * 0.88).clamp(80.0, 2000.0);
  }

  double get _wallLeft {
    final bgWallRect = background.getWallRect();
    return bgWallRect.left + (bgWallRect.width - _wallWidth) / 2;
  }

  double get _wallTop {
    final bgWallRect = background.getWallRect();
    return bgWallRect.top + bgWallRect.height * 0.03;
  }

  // Roller is a square sprite (600x600 PNG) — size proportional to wall.
  static const double _rollerContactFraction = (400 - 200) / 600; // 1/3 of sprite

  double get _rollerSize =>
      (_rollerWidthFraction / _rollerContactFraction * _wallWidth)
          .clamp(70.0, 400.0);

  PaintRollerGame();

  @override
  Color backgroundColor() => const Color(0xFFBCF9F1); // match ceiling color

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    roundState = GameRoundState(maxStrokes: _maxStrokes);

    // Background with homebackground.png
    background = BackgroundComponent(size: size);
    add(background);

    // Wait for background image to load so getWallRect() works
    await background.onLoad();

    wall = WallComponent(
      wallColor: _wallColor,
      dirtColor: _dirtColor,
      paintColor: _rollerPaintColor,
      position: Vector2(_wallLeft, _wallTop),
      size: Vector2(_wallWidth, _wallHeight),
    );
    add(wall);

    // Pattern outline overlay: draws shape strokes above paint stripes
    patternOverlay = WallPatternOverlay(wall: wall);
    patternOverlay.position = Vector2(_wallLeft, _wallTop);
    patternOverlay.size = Vector2(_wallWidth, _wallHeight);
    patternOverlay.priority = 15; // above paint stripes (0), below roller (20)
    add(patternOverlay);

    roller = RollerComponent(
      speedMultiplier: _rollerSpeedMultiplier,
      wallWidth: _wallWidth,
      wallLeft: _wallLeft,
      wallTop: _wallTop,
      wallHeight: _wallHeight,
      position: Vector2(0, 0),
      size: Vector2(_rollerSize, _rollerSize),
    );
    roller.setDrawSize(_rollerSize);
    roller.priority = 20; // above paint stripes
    add(roller);

    // Border rendered on top of everything
    wallBorder = WallBorderComponent(
      position: Vector2(_wallLeft, _wallTop),
      size: Vector2(_wallWidth, _wallHeight),
    );
    wallBorder.priority = 30; // above roller and paint stripes
    add(wallBorder);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isMounted) {
      background.size = size;
      wall.position = Vector2(_wallLeft, _wallTop);
      wall.size = Vector2(_wallWidth, _wallHeight);
      patternOverlay.position = Vector2(_wallLeft, _wallTop);
      patternOverlay.size = Vector2(_wallWidth, _wallHeight);
      wallBorder.position = Vector2(_wallLeft, _wallTop);
      wallBorder.size = Vector2(_wallWidth, _wallHeight);

      roller.updateLayout(
        newWallWidth: _wallWidth,
        newWallLeft: _wallLeft,
        newWallTop: _wallTop,
        newWallHeight: _wallHeight,
      );
      roller.setDrawSize(_rollerSize);
    }
  }

  void configure({
    required double rollerWidthFraction,
    required double rollerSpeedMultiplier,
    required int maxStrokes,
    required RoomDefinition room,
    int houseTier = 0,
    int cycleLevel = 1,
    Color borderColor = const Color(0xFFD3D3D3),
    Color? rollerPaintColor,
    BlendMode? rollerPaintBlendMode,
  }) {
    _rollerWidthFraction = rollerWidthFraction;
    _rollerSpeedMultiplier = rollerSpeedMultiplier;
    _maxStrokes = maxStrokes;
    _wallColor = room.wallColor;
    _dirtColor = room.dirtColor;
    if (rollerPaintColor != null) _rollerPaintColor = rollerPaintColor;
    if (rollerPaintBlendMode != null) _rollerPaintBlendMode = rollerPaintBlendMode;

    if (isMounted) {
      wall.updateColors(room.wallColor, room.dirtColor, _rollerPaintColor);
      wall.updateHouseTier(houseTier, level: cycleLevel);
      wall.updateSeed(_wallSeedCounter);
      wallBorder.borderColor = const Color(0xFF000000);
      roller.speedMultiplier = rollerSpeedMultiplier;
      roller.setPaintColor(_rollerPaintColor);
      roller.setDrawSize(_rollerSize);
      _startNewRound();
    }
  }

  /// Update roller parameters live (e.g. after purchasing an upgrade)
  /// without resetting the current round.
  void updateRollerSettings({
    required double rollerWidthFraction,
    required double rollerSpeedMultiplier,
    required int maxStrokes,
  }) {
    _rollerWidthFraction = rollerWidthFraction;
    _rollerSpeedMultiplier = rollerSpeedMultiplier;
    final strokesChanged = _maxStrokes != maxStrokes;
    _maxStrokes = maxStrokes;
    if (isMounted) {
      roller.speedMultiplier = rollerSpeedMultiplier;
      roller.setDrawSize(_rollerSize);
      if (strokesChanged) {
        _startNewRound();
      }
    }
  }

  /// Change the roller skin at runtime.
  void setRollerSkin(String skin) {
    if (isMounted) {
      roller.setSkin(skin);
    }
  }

  /// Change the paint color at runtime (e.g. when equipping a new skin).
  void setRollerPaintColor(Color color) {
    _rollerPaintColor = color;
    if (isMounted) {
      roller.setPaintColor(color);
    }
  }

  void _startNewRound() {
    children.whereType<PaintStripeComponent>().toList().forEach(remove);
    roundState.reset(_maxStrokes);
    _wallSeedCounter++;
    wall.updateSeed(_wallSeedCounter);
  }

  void startNewRound() => _startNewRound();

  /// Fast-forward the wet edge glow on all stripes so the paint looks dry.
  void quickDryStripes() {
    for (final stripe in children.whereType<PaintStripeComponent>()) {
      stripe.quickDry();
    }
  }

  @override
  void update(double dt) {
    super.update(dt); // updates all children (roller recalcs position, etc.)

    // Apply wall slide offset AFTER children update, so it doesn't fight
    // with roller.update() which sets position.x from wallLeft each frame.
    if (wallSlide != 0.0) {
      final offset = wallSlide * size.x;
      wall.position.x = _wallLeft + offset;
      patternOverlay.position.x = _wallLeft + offset;
      wallBorder.position.x = _wallLeft + offset;
      for (final stripe in children.whereType<PaintStripeComponent>()) {
        stripe.position.x = stripe.baseX + offset;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!roundState.isActive || roller.isPainting || isTransitioning) return;

    roller.triggerPaintStroke();

    final rollerContactWidth = _rollerSize * _rollerContactFraction;

    double stripeX = roller.pixelX - rollerContactWidth / 2;
    final wallRight = _wallLeft + _wallWidth;
    if (stripeX < _wallLeft) stripeX = _wallLeft;
    double clampedWidth = rollerContactWidth;
    if (stripeX + clampedWidth > wallRight) {
      clampedWidth = wallRight - stripeX;
    }

    final normLeft = (stripeX - _wallLeft) / _wallWidth;
    final normRight = (stripeX + clampedWidth - _wallLeft) / _wallWidth;
    roundState.addStripe(normLeft, normRight);

    final stripe = PaintStripeComponent(
      paintColor: _rollerPaintColor,
      paintBlendMode: _rollerPaintBlendMode,
      position: Vector2(stripeX, _wallTop),
      size: Vector2(clampedWidth, _wallHeight),
      fillDirection: StripeFillDirection.bottomToTop,
    );
    add(stripe);

    final combo = roundState.strokesUsed; // 1-based after addStripe

    final splatOrigin = Vector2(roller.pixelX, _wallTop + _wallHeight * 0.82);
    _spawnSplats(splatOrigin, rollerContactWidth, combo);

    // Floating coverage text with combo
    _spawnCoverageText(roller.pixelX, combo);

    onStripePainted?.call();

    if (!roundState.isActive) {
      // Coverage shimmer for NICE (90%+), GREAT (95%+), and PERFECT (100%)
      if (roundState.getCoverageDisplayPercent() >= 90) {
        final shimmer = PerfectShimmerComponent(
          position: Vector2(_wallLeft, _wallTop),
          size: Vector2(_wallWidth, _wallHeight),
        );
        shimmer.priority = 28; // above stripes, below border
        add(shimmer);
      }
      roundState.showingResults = true;
      onRoundComplete?.call(roundState.coveragePercent, roundState.getCoverageDisplayPercent());
    }
  }

  void _spawnCoverageText(double centerX, int combo) {
    final coveragePct = roundState.getCoverageDisplayPercent();
    final text = FloatingCoverageText(
      text: '$coveragePct%',
      color: Colors.white,
      comboCount: combo,
      position: Vector2(centerX - 70, _wallTop + _wallHeight * 0.25),
    );
    text.priority = 35; // above everything
    add(text);
  }

  void _spawnSplats(Vector2 origin, double contactWidth, int combo) {
    // Scale particle count with combo: 14 base, up to 24 at high combo
    final count = combo >= 5 ? 24 : combo >= 3 ? 18 : 14;
    final particles = PaintSplatParticle.burst(
      color: _rollerPaintColor,
      origin: origin,
      count: count,
      spreadWidth: contactWidth * 0.8,
    );
    for (final p in particles) {
      p.priority = 25; // above stripes, below border
      add(p);
    }
  }
}
