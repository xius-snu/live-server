import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A single paint splat particle. Pre-allocates Paint objects to avoid GC churn.
class PaintSplatParticle extends PositionComponent {
  final Color color;
  double _vx;
  double _vy;
  double _life;
  final double _maxLife;
  final double _radius;
  final bool _isBlob;
  static const double _gravity = 500.0;

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
        _hasHighlight = radius > 3,
        super(size: Vector2(radius * 2, radius * 2));

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }
    _vy += _gravity * dt;
    position.x += _vx * dt;
    position.y += _vy * dt;
    _vx *= 0.97;
  }

  @override
  void render(Canvas canvas) {
    final progress = 1.0 - (_life / _maxLife);
    final opacity = (1.0 - progress * progress).clamp(0.0, 1.0);
    final scale = _isBlob ? 1.0 + progress * 0.3 : 1.0 - progress * 0.5;

    _mainPaint.color = Color.fromRGBO(color.red, color.green, color.blue, opacity * 0.85);
    canvas.drawCircle(Offset.zero, _radius * scale, _mainPaint);

    if (_hasHighlight && opacity > 0.3) {
      _highlightPaint.color = Color.fromRGBO(255, 255, 255, opacity * 0.3);
      canvas.drawCircle(
        Offset(-_radius * 0.25, -_radius * 0.25),
        _radius * scale * 0.35,
        _highlightPaint,
      );
    }
  }

  static List<PaintSplatParticle> burst({
    required Color color,
    required Vector2 origin,
    int count = 14,
    double spreadWidth = 0,
    Random? rng,
  }) {
    final r = rng ?? Random();
    final particles = <PaintSplatParticle>[];

    for (int i = 0; i < count; i++) {
      final offsetX = spreadWidth > 0
          ? (r.nextDouble() - 0.5) * spreadWidth
          : 0.0;

      final isBlob = i < 3;

      final angle = -pi * 0.15 + r.nextDouble() * (-pi * 0.7);
      final speed = isBlob
          ? 60 + r.nextDouble() * 100
          : 100 + r.nextDouble() * 250;
      final life = isBlob
          ? 0.4 + r.nextDouble() * 0.3
          : 0.2 + r.nextDouble() * 0.35;
      final radius = isBlob
          ? 4.0 + r.nextDouble() * 4.0
          : 1.5 + r.nextDouble() * 3.0;

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
