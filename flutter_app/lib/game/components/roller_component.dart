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
  double _paintStartPos = 0; // start of stroke anim (resting edge)
  double _paintEndPos = 0;   // end of stroke anim (opposite edge)

  // Squash & stretch
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _squishTime = 0;
  bool _squishing = false;
  static const double _squishDuration = 0.12;

  // Paint loaded color (shown on roller cylinder)
  Color _loadedPaintColor = const Color(0xFFF5F0E8);

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

  void setPaintColor(Color c) {
    _loadedPaintColor = c;
  }

  /// Returns the roller's current position as a fraction (0.0 to 1.0)
  /// along its oscillation axis.
  double get normalizedPosition {
    final oscillation = (sin(_time * _baseSpeed * speedMultiplier) + 1) / 2;
    return oscillation;
  }

  /// Pixel X position (oscillates left-right along wall).
  double get pixelX => wallLeft + normalizedPosition * wallWidth;

  /// Pixel Y position (resting below wall).
  double get pixelY => wallTop + wallHeight + 2;

  double get restingY => wallTop + wallHeight + 2;

  bool get isPainting => _isPainting;

  /// Trigger the paint stroke animation.
  void triggerPaintStroke() {
    if (_isPainting) return;
    _isPainting = true;
    _paintAnimProgress = 0;
    _paintStartPos = wallTop + wallHeight + 2;
    _paintEndPos = wallTop - rollerDrawSize * 0.2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Paint stroke animation progress
    double strokeProgress = 0; // 0 = resting, 1 = peak
    if (_isPainting) {
      _paintAnimProgress += dt / _paintAnimDuration;
      if (_paintAnimProgress >= 1.0) {
        _paintAnimProgress = 1.0;
        _isPainting = false;
      }
      double t = _paintAnimProgress;
      if (t < 0.35) {
        strokeProgress = t / 0.35;
        if (t > 0.28 && !_squishing) {
          _squishing = true;
          _squishTime = 0;
        }
      } else {
        strokeProgress = 1.0 - ((t - 0.35) / 0.65);
      }
      strokeProgress = 1.0 - (1.0 - strokeProgress) * (1.0 - strokeProgress);
    }

    // Position the roller — oscillates left-right, rests below wall
    position.x = wallLeft + normalizedPosition * wallWidth - rollerDrawSize / 2;
    if (_isPainting) {
      position.y = _paintStartPos + (_paintEndPos - _paintStartPos) * strokeProgress;
    } else {
      position.y = wallTop + wallHeight + 2;
    }

    // Squash & stretch animation
    if (_squishing) {
      _squishTime += dt;
      final t = (_squishTime / _squishDuration).clamp(0.0, 1.0);
      if (t < 0.4) {
        final p = t / 0.4;
        _scaleX = 1.0 + 0.08 * p;
        _scaleY = 1.0 - 0.08 * p;
      } else {
        final p = (t - 0.4) / 0.6;
        final spring = 1.0 - p;
        _scaleX = 1.0 + 0.08 * spring;
        _scaleY = 1.0 - 0.08 * spring;
      }
      if (t >= 1.0) {
        _squishing = false;
        _scaleX = 1.0;
        _scaleY = 1.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    final cx = rollerDrawSize / 2;
    final cy = rollerDrawSize / 2;
    canvas.translate(cx, cy);
    canvas.scale(_scaleX, _scaleY);

    canvas.translate(-cx, -cy);

    if (_rollerSprite != null) {
      _rollerSprite!.render(
        canvas,
        position: Vector2(0, 0),
        size: Vector2(rollerDrawSize, rollerDrawSize),
      );
    } else {
      _renderPlaceholder(canvas);
    }

    canvas.restore();
  }

  void _renderPlaceholder(Canvas canvas) {
    final s = rollerDrawSize;

    final bodyPaint = Paint()..color = const Color(0xFFFFBBA8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.08, s * 0.12, s * 0.58, s * 0.25),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.12, s * 0.15, s * 0.2, s * 0.06),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

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
