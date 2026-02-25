import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Floating text showing coverage %. Cached layout, only opacity changes per frame.
class FloatingCoverageText extends PositionComponent {
  final String text;
  final Color color;
  final int comboCount;
  double _life = 0;
  static const double _totalLife = 1.0;
  static const double _riseSpeed = 60.0;

  late final double baseX;
  // Cached at creation — layout never changes
  late final TextPainter _painter;
  late final Color _mainColor;
  late final double _comboScale;
  late final double _cachedDx;
  late final double _cachedDy;

  FloatingCoverageText({
    required this.text,
    required this.color,
    this.comboCount = 1,
    required super.position,
  }) : super(size: Vector2(140, 50)) {
    baseX = position.x;

    _comboScale = comboCount >= 5
        ? 1.25
        : comboCount >= 3
            ? 1.12
            : 1.0;

    _mainColor = comboCount >= 5
        ? Color.lerp(color, const Color(0xFFFFD700), 0.7)!
        : comboCount >= 3
            ? Color.lerp(color, const Color(0xFFFFA500), 0.4)!
            : color;

    // Pre-layout text once
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w700,
          color: _mainColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _cachedDx = (size.x - _painter.width) / 2;
    _cachedDy = (size.y - _painter.height) / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= _totalLife) {
      removeFromParent();
      return;
    }
    position.y -= _riseSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final t = (_life / _totalLife).clamp(0.0, 1.0);

    double scale;
    double opacity;

    if (t < 0.15) {
      final p = t / 0.15;
      scale = p < 0.7 ? (p / 0.7) * 1.1 : 1.1 - 0.1 * ((p - 0.7) / 0.3);
      opacity = p.clamp(0.0, 1.0);
    } else if (t < 0.55) {
      final p = (t - 0.15) / 0.4;
      scale = 1.0 + 0.03 * sin(p * pi);
      opacity = 1.0;
    } else {
      final p = (t - 0.55) / 0.45;
      scale = 1.0 - 0.15 * p;
      opacity = (1.0 - p * p).clamp(0.0, 1.0);
    }

    if (opacity <= 0.01) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    final s = scale * _comboScale;
    canvas.scale(s, s);
    canvas.translate(-size.x / 2, -size.y / 2);

    // Apply opacity via saveLayer for the whole text (avoids re-layout)
    if (opacity < 0.99) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    }

    _painter.paint(canvas, Offset(_cachedDx, _cachedDy));

    if (opacity < 0.99) {
      canvas.restore();
    }

    canvas.restore();
  }
}
