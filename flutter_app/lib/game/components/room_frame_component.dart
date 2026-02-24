import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Clean, cartoonish room frame around the wall.
/// Simple baseboard, thin crown molding, and a floor gradient.
class RoomFrameComponent extends PositionComponent {
  Color wallColor;
  Color paintColor;
  int houseTier;

  static const double baseboardHeight = 12.0;
  static const double crownHeight = 6.0;
  static const double floorDepth = 14.0;

  RoomFrameComponent({
    required this.wallColor,
    required this.paintColor,
    this.houseTier = 0,
    required super.position,
    required super.size,
  });

  void updateColors(Color wall, Color paint) {
    wallColor = wall;
    paintColor = paint;
  }

  void updateHouseTier(int tier) {
    houseTier = tier;
  }

  @override
  void render(Canvas canvas) {
    final wallW = size.x;
    final wallH = size.y;

    final baseColor = _darken(wallColor, 0.25);
    final crownColor = _lighten(wallColor, 0.12);
    final floorColor = _darken(wallColor, 0.40);

    // === Crown Molding (above wall) — simple solid bar ===
    canvas.drawRect(
      Rect.fromLTWH(0, -crownHeight, wallW, crownHeight),
      Paint()..color = crownColor,
    );
    // Bottom line
    canvas.drawLine(
      Offset(0, 0),
      Offset(wallW, 0),
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..strokeWidth = 1.0,
    );

    // === Baseboard (bottom of wall) — solid bar with a highlight ===
    canvas.drawRect(
      Rect.fromLTWH(0, wallH, wallW, baseboardHeight),
      Paint()..color = baseColor,
    );
    // Top highlight
    canvas.drawLine(
      Offset(0, wallH),
      Offset(wallW, wallH),
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..strokeWidth = 1.0,
    );

    // === Floor hint (below baseboard) — fade to background ===
    final floorTop = wallH + baseboardHeight;
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, wallW, floorDepth),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            floorColor.withOpacity(0.3),
            floorColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, floorTop, wallW, floorDepth)),
    );
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
