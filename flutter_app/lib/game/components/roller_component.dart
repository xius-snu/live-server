import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';

class RollerComponent extends PositionComponent {
  double speedMultiplier;
  double wallWidth;
  double wallLeft;
  double wallTop;
  double wallHeight;
  double _time = 0;

  double rollerDrawSize = 100;

  Sprite? _rollerSprite;
  String _currentSkin = 'default';

  // Paint stroke animation
  bool _isPainting = false;
  double _paintAnimProgress = 0;
  double _paintStartPos = 0;
  double _paintEndPos = 0;

  // Cached per-frame value to avoid double sin() call
  double _cachedNormPos = 0.5;

  // Pre-allocated render vector (avoids GC churn)
  final Vector2 _renderSize = Vector2.zero();

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

  double get normalizedPosition => _cachedNormPos;

  double get pixelX => wallLeft + _cachedNormPos * wallWidth;
  double get pixelY => wallTop + wallHeight + kRollerYOffset;
  double get restingY => wallTop + wallHeight + kRollerYOffset;

  bool get isPainting => _isPainting;

  void triggerPaintStroke() {
    if (_isPainting) return;
    _isPainting = true;
    _paintAnimProgress = 0;
    _paintStartPos = wallTop + wallHeight + kRollerYOffset;
    _paintEndPos = wallTop - rollerDrawSize * kRollerPaintEndOffsetFraction;
  }

  @override
  void update(double dt) {
    _time += dt;

    // Cache normalized position (one sin() per frame)
    _cachedNormPos = (sin(_time * kRollerBaseSpeed * speedMultiplier) + 1) * 0.5;

    // Paint stroke animation
    double strokeProgress = 0;
    if (_isPainting) {
      _paintAnimProgress += dt / kPaintAnimDuration;
      if (_paintAnimProgress >= 1.0) {
        _paintAnimProgress = 1.0;
        _isPainting = false;
      }
      final t = _paintAnimProgress;
      if (t < kPaintAnimUpswingFraction) {
        strokeProgress = t / kPaintAnimUpswingFraction;
      } else {
        strokeProgress = 1.0 - ((t - kPaintAnimUpswingFraction) / kPaintAnimDownswingFraction);
      }
      strokeProgress = 1.0 - (1.0 - strokeProgress) * (1.0 - strokeProgress);
    }

    // Position
    position.x = wallLeft + _cachedNormPos * wallWidth - rollerDrawSize / 2;
    position.y = _isPainting
        ? _paintStartPos + (_paintEndPos - _paintStartPos) * strokeProgress
        : wallTop + wallHeight + kRollerYOffset;
  }

  @override
  void render(Canvas canvas) {
    if (_rollerSprite != null) {
      _renderSize.x = rollerDrawSize;
      _renderSize.y = rollerDrawSize;
      _rollerSprite!.render(canvas, size: _renderSize);
    }
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
