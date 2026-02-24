import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A single paint splat particle that bursts from the roller on tap.
/// Launches with random velocity, follows gravity, fades and dies.
class PaintSplatParticle extends PositionComponent {
  final Color color;
  double _vx;
  double _vy;
  double _life;
  final double _maxLife;
  final double _radius;
  static const double _gravity = 400.0; // px/s^2

  PaintSplatParticle({
    required this.color,
    required double vx,
    required double vy,
    required double life,
    required double radius,
    required super.position,
  })  : _vx = vx,
        _vy = vy,
        _life = life,
        _maxLife = life,
        _radius = radius,
        super(size: Vector2(radius * 2, radius * 2));

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }

    // Physics
    _vy += _gravity * dt;
    position.x += _vx * dt;
    position.y += _vy * dt;

    // Slow down horizontal
    _vx *= 0.98;
  }

  @override
  void render(Canvas canvas) {
    final progress = 1.0 - (_life / _maxLife); // 0 -> 1
    final opacity = (1.0 - progress * progress).clamp(0.0, 1.0); // fade out
    final scale = 1.0 - progress * 0.4; // shrink slightly

    final paint = Paint()..color = color.withOpacity(opacity * 0.8);
    canvas.drawCircle(
      Offset.zero,
      _radius * scale,
      paint,
    );

    // Tiny highlight
    if (opacity > 0.3) {
      canvas.drawCircle(
        Offset(-_radius * 0.2, -_radius * 0.2),
        _radius * scale * 0.3,
        Paint()..color = Colors.white.withOpacity(opacity * 0.2),
      );
    }
  }

  /// Spawn a burst of particles at the given position.
  static List<PaintSplatParticle> burst({
    required Color color,
    required Vector2 origin,
    int count = 6,
    Random? rng,
  }) {
    final r = rng ?? Random();
    return List.generate(count, (_) {
      final angle = -pi * 0.1 + r.nextDouble() * (-pi * 0.8); // mostly upward
      final speed = 80 + r.nextDouble() * 180;
      final life = 0.3 + r.nextDouble() * 0.4;
      final radius = 2.0 + r.nextDouble() * 3.5;

      return PaintSplatParticle(
        color: color,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: life,
        radius: radius,
        position: origin.clone(),
      );
    });
  }
}
