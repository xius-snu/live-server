import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PaintStripeComponent extends PositionComponent {
  final Color paintColor;
  double _animProgress = 0;
  // Match the roller's upswing duration (0.35 of 0.3s paint anim)
  static const double _animDuration = 0.105; // seconds

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
    // Paint grows from bottom to top, matching the roller sweeping upward
    final animatedHeight = size.y * _animProgress;
    final yOffset = size.y - animatedHeight;

    // Main paint stripe
    final paint = Paint()..color = paintColor.withOpacity(0.85);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, yOffset, size.x, animatedHeight),
      const Radius.circular(1),
    );
    canvas.drawRRect(rect, paint);

    // Subtle edge highlights
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, yOffset),
      Offset(0, size.y),
      edgePaint,
    );
    canvas.drawLine(
      Offset(size.x, yOffset),
      Offset(size.x, size.y),
      edgePaint,
    );
  }
}
