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

  // Roller is a square sprite (600x600 PNG) — size proportional to wall
  double get _rollerSize => (_wallWidth * 0.16).clamp(70.0, 130.0);

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
      _startNewRound();
    }
  }

  void _startNewRound() {
    children.whereType<PaintStripeComponent>().toList().forEach(remove);
    roundState.reset(_maxStrokes);
  }

  void startNewRound() => _startNewRound();

  @override
  void onTapDown(TapDownEvent event) {
    if (!roundState.isActive) return;

    final rollerNorm = roller.normalizedPosition;
    final halfWidth = _rollerWidthFraction / 2;

    // Trigger the roller paint stroke animation (swoosh up-down)
    roller.triggerPaintStroke();

    // Add to game state (uses clamped intervals internally)
    roundState.addStripe(rollerNorm, halfWidth);

    // Calculate visual stripe position, CLAMPED to wall bounds
    final stripePixelWidth = _rollerWidthFraction * _wallWidth;
    double stripeX = _wallLeft + rollerNorm * _wallWidth - stripePixelWidth / 2;

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
      final bonus = roundState.getCoverageBonus();
      roundState.coverageBonusMultiplier = bonus;
      roundState.showingResults = true;
      onRoundComplete?.call(roundState.coveragePercent, bonus);
    }
  }
}
