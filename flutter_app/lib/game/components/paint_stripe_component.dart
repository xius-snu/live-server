import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';

enum StripeFillDirection {
  bottomToTop,
  topToBottom,
  rightToLeft,
  leftToRight,
}

/// Paint stripe with wet-edge glow: 3 gradient highlights that fade as paint dries.
class PaintStripeComponent extends PositionComponent {
  final Color paintColor;
  final BlendMode paintBlendMode;
  final StripeFillDirection fillDirection;
  double _animProgress = 0;
  double _age = 0;
  bool _done = false; // skip update once fully dried

  late final double baseX;
  late final Paint _basePaint;

  PaintStripeComponent({
    required this.paintColor,
    this.paintBlendMode = BlendMode.srcOver,
    required super.position,
    required super.size,
    this.fillDirection = StripeFillDirection.bottomToTop,
    int? seed,
  }) {
    baseX = position.x;
    _basePaint = Paint()
      ..color = paintColor
      ..blendMode = paintBlendMode;
  }

  void quickDry() {
    _age = kStripeWetDuration;
  }

  @override
  void update(double dt) {
    if (_done) return;
    _age += dt;
    if (_animProgress < 1.0) {
      _animProgress = (_animProgress + dt / kStripeFillDuration).clamp(0.0, 1.0);
    }
    if (_animProgress >= 1.0 && _age >= kStripeWetDuration) {
      _done = true;
    }
  }

  @override
  void render(Canvas canvas) {
    Rect paintedRect;
    switch (fillDirection) {
      case StripeFillDirection.bottomToTop:
        final h = size.y * _animProgress;
        if (h < kStripeMinRenderHeight) return;
        paintedRect = Rect.fromLTWH(0, size.y - h, size.x, h);
        break;
      case StripeFillDirection.topToBottom:
        final h = size.y * _animProgress;
        if (h < kStripeMinRenderHeight) return;
        paintedRect = Rect.fromLTWH(0, 0, size.x, h);
        break;
      case StripeFillDirection.rightToLeft:
        final w = size.x * _animProgress;
        if (w < kStripeMinRenderHeight) return;
        paintedRect = Rect.fromLTWH(size.x - w, 0, w, size.y);
        break;
      case StripeFillDirection.leftToRight:
        final w = size.x * _animProgress;
        if (w < kStripeMinRenderHeight) return;
        paintedRect = Rect.fromLTWH(0, 0, w, size.y);
        break;
    }

    canvas.drawRect(paintedRect, _basePaint);

    // Wet edge glow — identical to original visual
    if (_age < kStripeWetDuration && paintedRect.width > 2) {
      final wetProgress = (_age / kStripeWetDuration).clamp(0.0, 1.0);
      final glowOpacity = (1.0 - wetProgress * wetProgress) * kStripeGlowOpacityMultiplier;
      if (glowOpacity > 0.01) {
        final glowWidth = paintedRect.width * kStripeGlowWidthFraction;

        // Left edge highlight
        final leftRect = Rect.fromLTWH(
          paintedRect.left, paintedRect.top, glowWidth, paintedRect.height,
        );
        canvas.drawRect(
          leftRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(glowOpacity),
                Colors.white.withOpacity(0),
              ],
            ).createShader(leftRect),
        );

        // Right edge highlight
        final rightRect = Rect.fromLTWH(
          paintedRect.right - glowWidth, paintedRect.top, glowWidth, paintedRect.height,
        );
        canvas.drawRect(
          rightRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Colors.white.withOpacity(glowOpacity),
                Colors.white.withOpacity(0),
              ],
            ).createShader(rightRect),
        );

        // Top edge shimmer
        final shimmerHeight = paintedRect.height * kStripeTopShimmerHeightFraction;
        final topRect = Rect.fromLTWH(
          paintedRect.left, paintedRect.top, paintedRect.width, shimmerHeight,
        );
        canvas.drawRect(
          topRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(glowOpacity * kStripeTopShimmerOpacityMultiplier),
                Colors.white.withOpacity(0),
              ],
            ).createShader(topRect),
        );
      }
    }
  }
}
