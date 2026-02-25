import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A white shimmer that sweeps diagonally from top-left to bottom-right
/// across the wall when the player achieves 100% coverage. Self-removes when done.
class PerfectShimmerComponent extends PositionComponent {
  double _time = 0;
  static const double _duration = 0.65; // total sweep time
  static const double _bandWidth = 0.3; // fraction of diagonal for the shimmer band

  PerfectShimmerComponent({
    required super.position,
    required super.size,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_time / _duration).clamp(0.0, 1.0);

    // Fade in at start, fade out at end
    final fadeMul = progress < 0.15
        ? progress / 0.15
        : progress > 0.7
            ? (1.0 - progress) / 0.3
            : 1.0;

    final opacity = 0.4 * fadeMul;
    if (opacity < 0.01) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));

    // Diagonal sweep: band moves from top-left to bottom-right
    // We use a rotated gradient band that slides along the diagonal
    final diagonal = size.x + size.y;
    final bandCenter = -_bandWidth * diagonal + progress * (1.0 + 2 * _bandWidth) * diagonal;
    final bandHalf = _bandWidth * diagonal * 0.5;

    // Draw using a rotated approach: translate to band position along diagonal
    // The band is perpendicular to the top-left -> bottom-right diagonal
    final angle = 0.785; // ~45 degrees in radians

    canvas.save();
    // Rotate canvas 45 degrees
    canvas.rotate(angle);

    // In rotated space, the band sweeps horizontally
    final bandLeft = bandCenter - bandHalf;
    final bandRight = bandCenter + bandHalf;

    // Make the rect tall enough to cover the wall in rotated space
    final bigHeight = diagonal;

    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(opacity * 0.6),
          Colors.white.withOpacity(opacity),
          Colors.white.withOpacity(opacity * 0.6),
          Colors.white.withOpacity(0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(bandLeft, -bigHeight, bandRight - bandLeft, bigHeight * 2));

    canvas.drawRect(
      Rect.fromLTWH(bandLeft, -bigHeight, bandRight - bandLeft, bigHeight * 2),
      shimmerPaint,
    );

    canvas.restore();
    canvas.restore();
  }
}
