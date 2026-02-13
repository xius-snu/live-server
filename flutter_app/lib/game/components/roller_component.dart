import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

class RollerComponent extends PositionComponent {
  double speedMultiplier;
  double wallWidth;
  double wallLeft;
  double wallTop;
  double wallHeight;
  double _time = 0;
  static const double _baseSpeed = 2.2; // radians per second

  // Roller visual dimensions — 1:1 aspect ratio to match PNG
  double rollerDrawSize = 100;

  Sprite? _rollerSprite;
  String _currentSkin = 'default';

  // Paint stroke animation
  bool _isPainting = false;
  double _paintAnimProgress = 0;
  static const double _paintAnimDuration = 0.3; // seconds
  double _paintStartY = 0;
  double _paintEndY = 0;

  RollerComponent({
    this.speedMultiplier = 1.0,
    required this.wallWidth,
    required this.wallLeft,
    required this.wallTop,
    required this.wallHeight,
    super.position,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _loadSkin('default');
  }

  Future<void> _loadSkin(String skin) async {
    try {
      final image = await Flame.images.load('rollers/$skin.png');
      _rollerSprite = Sprite(image);
      _currentSkin = skin;
    } catch (e) {
      _rollerSprite = null;
    }
  }

  Future<void> setSkin(String skin) async {
    if (skin != _currentSkin) {
      await _loadSkin(skin);
    }
  }

  /// Returns the roller's current position as a fraction (0.0 to 1.0) across the wall.
  double get normalizedPosition {
    final oscillation = (sin(_time * _baseSpeed * speedMultiplier) + 1) / 2;
    return oscillation;
  }

  double get pixelX {
    return wallLeft + normalizedPosition * wallWidth;
  }

  /// The resting Y position (below the wall)
  double get restingY => wallTop + wallHeight + 8;

  bool get isPainting => _isPainting;

  /// Trigger the up-down paint animation.
  void triggerPaintStroke() {
    if (_isPainting) return;
    _isPainting = true;
    _paintAnimProgress = 0;
    _paintStartY = restingY;
    _paintEndY = wallTop - rollerDrawSize * 0.2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Horizontal position: oscillate, center the roller on the position
    position.x = pixelX - rollerDrawSize / 2;

    if (_isPainting) {
      _paintAnimProgress += dt / _paintAnimDuration;
      if (_paintAnimProgress >= 1.0) {
        _paintAnimProgress = 1.0;
        _isPainting = false;
      }
      // Easing: rush up, glide back down
      double t = _paintAnimProgress;
      double yProgress;
      if (t < 0.35) {
        // Go up (0 -> 1)
        yProgress = t / 0.35;
      } else {
        // Come back down (1 -> 0)
        yProgress = 1.0 - ((t - 0.35) / 0.65);
      }
      // Ease-out for the upswing, ease-in for the downswing
      yProgress = 1.0 - (1.0 - yProgress) * (1.0 - yProgress);
      position.y = _paintStartY + (_paintEndY - _paintStartY) * yProgress;
    } else {
      position.y = restingY;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_rollerSprite != null) {
      // Draw at 1:1 aspect ratio (PNG is 600x600)
      _rollerSprite!.render(
        canvas,
        position: Vector2(0, 0),
        size: Vector2(rollerDrawSize, rollerDrawSize),
      );
    } else {
      _renderPlaceholder(canvas);
    }
  }

  void _renderPlaceholder(Canvas canvas) {
    final s = rollerDrawSize;

    // Roller cylinder (top portion)
    final bodyPaint = Paint()..color = const Color(0xFFFFBBA8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.08, s * 0.12, s * 0.58, s * 0.25),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    // Highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.12, s * 0.15, s * 0.2, s * 0.06),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    // Handle arm
    final handlePaint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.48, s * 0.37)
        ..lineTo(s * 0.58, s * 0.50)
        ..lineTo(s * 0.58, s * 0.62),
      handlePaint,
    );

    // Handle grip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.50, s * 0.60, s * 0.16, s * 0.28),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFFFAA44),
    );
  }

  void updateLayout({
    required double newWallWidth,
    required double newWallLeft,
    required double newWallTop,
    required double newWallHeight,
  }) {
    wallWidth = newWallWidth;
    wallLeft = newWallLeft;
    wallTop = newWallTop;
    wallHeight = newWallHeight;
  }

  void setDrawSize(double s) {
    rollerDrawSize = s;
    size = Vector2(s, s);
  }
}
