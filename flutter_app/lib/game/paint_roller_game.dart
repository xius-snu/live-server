import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'components/wall_component.dart';
import 'components/roller_component.dart';
import 'components/paint_stripe_component.dart';
import '../models/house.dart';

class PaintRollerGame extends FlameGame with TapCallbacks {
  late WallComponent wall;
  late RollerComponent roller;
  late GameRoundState roundState;

  // Callback for when round ends
  void Function(double coverage, int bonus)? onRoundComplete;
  // Callback for when a stripe is painted
  void Function()? onStripePainted;

  // Config from upgrades
  double _rollerWidthFraction = 0.15; // base 15% of wall per stroke
  double _rollerSpeedMultiplier = 1.0;
  int _maxStrokes = 6;
  Color _wallColor = const Color(0xFFE8DCC8);
  Color _dirtColor = const Color(0xFFC4A882);
  Color _paintColor = const Color(0xFFF5F0E8);

  // Wall layout
  static const double _wallMarginX = 28;
  static const double _wallTopMargin = 44;
  static const double _rollerAreaHeight = 120;
  static const double _bottomHudHeight = 130;

  double get _wallWidth => size.x - _wallMarginX * 2;
  double get _wallHeight =>
      (size.y - _wallTopMargin - _rollerAreaHeight - _bottomHudHeight)
          .clamp(80.0, 2000.0);
  double get _wallLeft => _wallMarginX;
  double get _wallTop => _wallTopMargin;

  // Roller is a square sprite (600x600 PNG) — size proportional to wall.
  // The actual roller contact line in the PNG spans x=200..400 (200px of 600px),
  // i.e. the middle 1/3 of the sprite is the part that touches the wall.
  static const double _rollerContactFraction = (400 - 200) / 600; // 1/3 of sprite

  // Roller size scales with wall width and the "Wider Roller" upgrade.
  // The contact line (1/3 of sprite) should cover _rollerWidthFraction of the wall.
  // So: spriteSize * _rollerContactFraction = _rollerWidthFraction * _wallWidth
  //     spriteSize = _rollerWidthFraction / _rollerContactFraction * _wallWidth
  double get _rollerSize =>
      (_rollerWidthFraction / _rollerContactFraction * _wallWidth)
          .clamp(70.0, 400.0);

  PaintRollerGame();

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    roundState = GameRoundState(maxStrokes: _maxStrokes);

    wall = WallComponent(
      wallColor: _wallColor,
      dirtColor: _dirtColor,
      paintColor: _paintColor,
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
    add(roller);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isMounted) {
      wall.position = Vector2(_wallLeft, _wallTop);
      wall.size = Vector2(_wallWidth, _wallHeight);

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
  }) {
    _rollerWidthFraction = rollerWidthFraction;
    _rollerSpeedMultiplier = rollerSpeedMultiplier;
    _maxStrokes = maxStrokes;
    _wallColor = room.wallColor;
    _dirtColor = room.dirtColor;
    _paintColor = room.paintColor;

    if (isMounted) {
      wall.updateColors(room.wallColor, room.dirtColor, room.paintColor);
      roller.speedMultiplier = rollerSpeedMultiplier;
      roller.setDrawSize(_rollerSize);
      _startNewRound();
    }
  }

  /// Update roller parameters live (e.g. after purchasing an upgrade)
  /// without resetting the current round.
  void updateRollerSettings({
    required double rollerWidthFraction,
    required double rollerSpeedMultiplier,
  }) {
    _rollerWidthFraction = rollerWidthFraction;
    _rollerSpeedMultiplier = rollerSpeedMultiplier;
    if (isMounted) {
      roller.speedMultiplier = rollerSpeedMultiplier;
      roller.setDrawSize(_rollerSize);
    }
  }

  void _startNewRound() {
    children.whereType<PaintStripeComponent>().toList().forEach(remove);
    roundState.reset(_maxStrokes);
  }

  void startNewRound() => _startNewRound();

  @override
  void onTapDown(TapDownEvent event) {
    if (!roundState.isActive || roller.isPainting) return;

    final rollerNorm = roller.normalizedPosition;

    // Trigger the roller paint stroke animation (swoosh up-down)
    roller.triggerPaintStroke();

    // The paint stripe width derives from the roller sprite's contact line.
    // In the 600x600 PNG, the contact line spans x=200..400 (1/3 of sprite).
    final rollerContactWidth = _rollerSize * _rollerContactFraction;
    final halfWidth = (rollerContactWidth / _wallWidth) / 2;

    // Add to game state (uses clamped intervals internally)
    roundState.addStripe(rollerNorm, halfWidth);

    // Visual stripe matches the contact line region of the rendered sprite.
    final stripePixelWidth = rollerContactWidth;
    // The sprite is centered on pixelX; the contact line center is at the
    // sprite center (x=300 in 600px), so the stripe is also centered on pixelX.
    double stripeX = roller.pixelX - stripePixelWidth / 2;

    // Clamp: left edge can't go before wall, right edge can't go past wall
    final wallRight = _wallLeft + _wallWidth;
    if (stripeX < _wallLeft) stripeX = _wallLeft;
    double clampedWidth = stripePixelWidth;
    if (stripeX + clampedWidth > wallRight) {
      clampedWidth = wallRight - stripeX;
    }

    final stripe = PaintStripeComponent(
      paintColor: _paintColor,
      position: Vector2(stripeX, _wallTop),
      size: Vector2(clampedWidth, _wallHeight),
    );
    add(stripe);

    onStripePainted?.call();

    // Check if round is over
    if (!roundState.isActive) {
      roundState.showingResults = true;
      onRoundComplete?.call(roundState.coveragePercent, roundState.getCoverageDisplayPercent());
    }
  }
}
