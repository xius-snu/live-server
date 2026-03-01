import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';

/// A white shimmer that sweeps diagonally from top-left to bottom-right
/// across the wall when the player achieves 100% coverage. Self-removes when done.
class PerfectShimmerComponent extends PositionComponent {
  double _time = 0;

  PerfectShimmerComponent({
    required super.position,
    required super.size,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= kShimmerDuration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_time / kShimmerDuration).clamp(0.0, 1.0);

    // Fade in at start, fade out at end
    final fadeMul = progress < kShimmerFadeInPhase
        ? progress / kShimmerFadeInPhase
        : progress > kShimmerFadeOutStart
            ? (1.0 - progress) / kShimmerFadeOutDuration
            : 1.0;

    final opacity = kShimmerBaseOpacity * fadeMul;
    if (opacity < 0.01) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));

    // Diagonal sweep: band moves from top-left to bottom-right
    // We use a rotated gradient band that slides along the diagonal
    final diagonal = size.x + size.y;
    final bandCenter = -kShimmerBandWidth * diagonal + progress * (1.0 + 2 * kShimmerBandWidth) * diagonal;
    final bandHalf = kShimmerBandWidth * diagonal * 0.5;

    // Draw using a rotated approach: translate to band position along diagonal
    // The band is perpendicular to the top-left -> bottom-right diagonal
    canvas.save();
    // Rotate canvas ~45 degrees
    canvas.rotate(kShimmerAngle);

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
        stops: kShimmerGradientStops,
      ).createShader(Rect.fromLTWH(bandLeft, -bigHeight, bandRight - bandLeft, bigHeight * 2));

    canvas.drawRect(
      Rect.fromLTWH(bandLeft, -bigHeight, bandRight - bandLeft, bigHeight * 2),
      shimmerPaint,
    );

    canvas.restore();
    canvas.restore();
  }
}
