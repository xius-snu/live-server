import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';

/// A single paint splat particle. Pre-allocates Paint objects to avoid GC churn.
class PaintSplatParticle extends PositionComponent {
  final Color color;
  double _vx;
  double _vy;
  double _life;
  final double _maxLife;
  final double _radius;
  final bool _isBlob;

  // Pre-allocated paints
  final Paint _mainPaint = Paint();
  final Paint _highlightPaint = Paint();
  final bool _hasHighlight;

  PaintSplatParticle({
    required this.color,
    required double vx,
    required double vy,
    required double life,
    required double radius,
    required super.position,
    bool isBlob = false,
  })  : _vx = vx,
        _vy = vy,
        _life = life,
        _maxLife = life,
        _radius = radius,
        _isBlob = isBlob,
        _hasHighlight = radius > kSplatHighlightMinRadius,
        super(size: Vector2(radius * 2, radius * 2));

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }
    _vy += kSplatGravity * dt;
    position.x += _vx * dt;
    position.y += _vy * dt;
    _vx *= kSplatVelocityDamping;
  }

  @override
  void render(Canvas canvas) {
    final progress = 1.0 - (_life / _maxLife);
    final opacity = (1.0 - progress * progress).clamp(0.0, 1.0);
    final scale = _isBlob ? 1.0 + progress * kSplatBlobGrowth : 1.0 - progress * kSplatSmallShrink;

    _mainPaint.color = Color.fromRGBO(color.red, color.green, color.blue, opacity * kSplatMainOpacity);
    canvas.drawCircle(Offset.zero, _radius * scale, _mainPaint);

    if (_hasHighlight && opacity > kSplatHighlightOpacity) {
      _highlightPaint.color = Color.fromRGBO(255, 255, 255, opacity * kSplatHighlightOpacity);
      canvas.drawCircle(
        Offset(-_radius * kSplatHighlightOffsetX.abs(), -_radius * kSplatHighlightOffsetY.abs()),
        _radius * scale * kSplatHighlightRadiusFactor,
        _highlightPaint,
      );
    }
  }

  static List<PaintSplatParticle> burst({
    required Color color,
    required Vector2 origin,
    int count = kSplatDefaultCount,
    double spreadWidth = 0,
    Random? rng,
  }) {
    final r = rng ?? Random();
    final particles = <PaintSplatParticle>[];

    for (int i = 0; i < count; i++) {
      final offsetX = spreadWidth > 0
          ? (r.nextDouble() - 0.5) * spreadWidth
          : 0.0;

      final isBlob = i < kSplatBlobThreshold;

      final angle = kSplatAngleStart + r.nextDouble() * kSplatAngleRange;
      final speed = isBlob
          ? kSplatBlobMinSpeed + r.nextDouble() * kSplatBlobSpeedVariance
          : kSplatSmallMinSpeed + r.nextDouble() * kSplatSmallSpeedVariance;
      final life = isBlob
          ? kSplatBlobMinLife + r.nextDouble() * kSplatBlobLifeVariance
          : kSplatSmallMinLife + r.nextDouble() * kSplatSmallLifeVariance;
      final radius = isBlob
          ? kSplatBlobMinRadius + r.nextDouble() * kSplatBlobRadiusVariance
          : kSplatSmallMinRadius + r.nextDouble() * kSplatSmallRadiusVariance;

      particles.add(PaintSplatParticle(
        color: color,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: life,
        radius: radius,
        isBlob: isBlob,
        position: Vector2(origin.x + offsetX, origin.y),
      ));
    }

    return particles;
  }
}
