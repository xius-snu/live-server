import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PaintStripeComponent extends PositionComponent {
  final Color paintColor;
  double _animProgress = 0;
  static const double _animDuration = 0.15; // seconds

  PaintStripeComponent({
    required this.paintColor,
    required super.position,
    required super.size,
  });

  @override
  void update(double dt) {
    super.update(dt);
    if (_animProgress < 1.0) {
      _animProgress = (_animProgress + dt / _animDuration).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    final animatedWidth = size.x * _animProgress;
    final xOffset = (size.x - animatedWidth) / 2;

    // Main paint stripe
    final paint = Paint()..color = paintColor.withOpacity(0.85);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(xOffset, 0, animatedWidth, size.y),
      const Radius.circular(1),
    );
    canvas.drawRRect(rect, paint);

    // Subtle edge highlights
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(xOffset, 0),
      Offset(xOffset, size.y),
      edgePaint,
    );
    canvas.drawLine(
      Offset(xOffset + animatedWidth, 0),
      Offset(xOffset + animatedWidth, size.y),
      edgePaint,
    );
  }
}
