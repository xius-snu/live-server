import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';

/// Draws a thick outer border around the wall area.
/// Added last in the game so it renders on top of paint stripes,
/// keeping paint visually contained inside the border.
class WallBorderComponent extends PositionComponent {
  Color borderColor;

  WallBorderComponent({
    required super.position,
    required super.size,
    this.borderColor = const Color(kDefaultBorderColor),
  });

  @override
  void render(Canvas canvas) {
    // Draw the border expanded outward by half the stroke width
    // so the entire stroke sits outside the wall rect.
    final half = kWallBorderStrokeWidth / 2;
    final outerRect = Rect.fromLTWH(
      -half,
      -half,
      size.x + kWallBorderStrokeWidth,
      size.y + kWallBorderStrokeWidth,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = kWallBorderStrokeWidth;

    canvas.drawRect(outerRect, borderPaint);
  }
}
