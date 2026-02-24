import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'components/wall_component.dart';
import 'components/roller_component.dart';
import 'components/paint_stripe_component.dart';
import 'components/paint_splat_particle.dart';
import 'components/background_component.dart';
import 'components/wall_border_component.dart';
import '../models/house.dart';
class PaintRollerGame extends FlameGame with TapCallbacks {
  late BackgroundComponent background;
  late WallComponent wall;
  late WallBorderComponent wallBorder;
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
  BlendMode _rollerPaintBlendMode = BlendMode.color;

  // Seed counter so wall patterns vary each round.
  int _wallSeedCounter = 0;

  // Reference width ensures difficulty is identical across all screen sizes.
  static const double _referenceWidth = 400.0;

  double get _wallWidth {
    final bgWallRect = background.getWallRect();
    final maxWallW = _referenceWidth;
    return bgWallRect.width.clamp(80.0, maxWallW);
  }

  double get _wallHeight {
    final bgWallRect = background.getWallRect();
    return (bgWallRect.height * 0.90).clamp(80.0, 2000.0);
  }

  double get _wallLeft {
    final bgWallRect = background.getWallRect();
    return bgWallRect.left + (bgWallRect.width - _wallWidth) / 2;
  }

  double get _wallTop {
    final bgWallRect = background.getWallRect();
    return bgWallRect.top + bgWallRect.height * 0.02;
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

  @override
  void update(double dt) {
    super.update(dt); // updates all children (roller recalcs position, etc.)

    // Apply wall slide offset AFTER children update, so it doesn't fight
    // with roller.update() which sets position.x from wallLeft each frame.
    if (wallSlide != 0.0) {
      final offset = wallSlide * size.x;
      wall.position.x = _wallLeft + offset;
      wallBorder.position.x = _wallLeft + offset;
      for (final stripe in children.whereType<PaintStripeComponent>()) {
        // Stripes are created at _wallLeft-relative positions.
        // Shift them by the same offset from their original x.
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

    final splatOrigin = Vector2(roller.pixelX, _wallTop + _wallHeight * 0.85);
    _spawnSplats(splatOrigin);

    onStripePainted?.call();

    if (!roundState.isActive) {
      roundState.showingResults = true;
      onRoundComplete?.call(roundState.coveragePercent, roundState.getCoverageDisplayPercent());
    }
  }

  void _spawnSplats(Vector2 origin) {
    final particles = PaintSplatParticle.burst(
      color: _rollerPaintColor,
      origin: origin,
      count: 5,
    );
    for (final p in particles) {
      add(p);
    }
  }
}
