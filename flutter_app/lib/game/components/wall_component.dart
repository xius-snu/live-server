import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WallComponent extends PositionComponent {
  Color wallColor;
  Color dirtColor;
  Color paintColor;
  final Random _rng = Random(42);
  late List<_DirtSpot> _dirtSpots;

  WallComponent({
    required this.wallColor,
    required this.dirtColor,
    required this.paintColor,
    super.position,
    super.size,
  });

  @override
  void onLoad() {
    super.onLoad();
    _generateDirtSpots();
  }

  void _generateDirtSpots() {
    // Inset dirt spots so they don't bleed outside the wall
    const margin = 10.0;
    _dirtSpots = List.generate(50, (_) {
      final radius = 3.0 + _rng.nextDouble() * 7;
      return _DirtSpot(
        x: margin + _rng.nextDouble() * (size.x - margin * 2),
        y: margin + _rng.nextDouble() * (size.y - margin * 2),
        radiusX: radius,
        radiusY: radius * 0.7,
      );
    });
  }

  void updateColors(Color wall, Color dirt, Color paint) {
    wallColor = wall;
    dirtColor = dirt;
    paintColor = paint;
    _generateDirtSpots();
  }

  @override
  void render(Canvas canvas) {
    final wallRect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Clip everything to wall bounds
    canvas.save();
    canvas.clipRect(wallRect);

    // Base wall color
    canvas.drawRect(wallRect, Paint()..color = wallColor);

    // Dirt spots — all safely inside bounds
    final dirtPaint = Paint()..color = dirtColor.withOpacity(0.35);
    for (final spot in _dirtSpots) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(spot.x, spot.y),
          width: spot.radiusX * 2,
          height: spot.radiusY * 2,
        ),
        dirtPaint,
      );
    }

    // Subtle gradient overlay for depth
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.black.withOpacity(0.08),
        ],
      ).createShader(wallRect);
    canvas.drawRect(wallRect, gradientPaint);

    // Thin border around wall
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(wallRect, borderPaint);

    canvas.restore();
  }
}

class _DirtSpot {
  final double x, y, radiusX, radiusY;
  const _DirtSpot({
    required this.x,
    required this.y,
    required this.radiusX,
    required this.radiusY,
  });
}
