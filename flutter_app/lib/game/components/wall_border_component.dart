import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Draws a thick outer border around the wall area.
/// Added last in the game so it renders on top of paint stripes,
/// keeping paint visually contained inside the border.
class WallBorderComponent extends PositionComponent {
  static const double strokeWidth = 4.0;

  Color borderColor;

  WallBorderComponent({
    required super.position,
    required super.size,
    this.borderColor = const Color(0xFFD3D3D3),
  });

  @override
  void render(Canvas canvas) {
    // Draw the border expanded outward by half the stroke width
    // so the entire stroke sits outside the wall rect.
    final half = strokeWidth / 2;
    final outerRect = Rect.fromLTWH(
      -half,
      -half,
      size.x + strokeWidth,
      size.y + strokeWidth,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRect(outerRect, borderPaint);
  }
}
