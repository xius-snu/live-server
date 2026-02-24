import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum StripeFillDirection {
  bottomToTop,
  topToBottom,
  rightToLeft,
  leftToRight,
}

/// Clean, cartoonish paint stripe that fills in the given direction.
class PaintStripeComponent extends PositionComponent {
  final Color paintColor;
  final BlendMode paintBlendMode;
  final StripeFillDirection fillDirection;
  double _animProgress = 0;
  // Match the roller's upswing duration (0.35 of 0.3s paint anim)
  static const double _animDuration = 0.105; // seconds

  /// Original x position at creation, used for wall slide offset.
  late final double baseX;

  PaintStripeComponent({
    required this.paintColor,
    this.paintBlendMode = BlendMode.srcOver,
    required super.position,
    required super.size,
    this.fillDirection = StripeFillDirection.bottomToTop,
    int? seed,
  }) {
    baseX = position.x;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_animProgress < 1.0) {
      _animProgress = (_animProgress + dt / _animDuration).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = paintColor
      ..blendMode = paintBlendMode;

    switch (fillDirection) {
      case StripeFillDirection.bottomToTop:
        final h = size.y * _animProgress;
        if (h < 1) return;
        canvas.drawRect(Rect.fromLTWH(0, size.y - h, size.x, h), paint);
        break;

      case StripeFillDirection.topToBottom:
        final h = size.y * _animProgress;
        if (h < 1) return;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, h), paint);
        break;

      case StripeFillDirection.rightToLeft:
        final w = size.x * _animProgress;
        if (w < 1) return;
        canvas.drawRect(Rect.fromLTWH(size.x - w, 0, w, size.y), paint);
        break;

      case StripeFillDirection.leftToRight:
        final w = size.x * _animProgress;
        if (w < 1) return;
        canvas.drawRect(Rect.fromLTWH(0, 0, w, size.y), paint);
        break;
    }
  }
}
