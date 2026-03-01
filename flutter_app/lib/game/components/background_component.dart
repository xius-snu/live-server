import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';

/// Renders homebackground.png as a full-screen background.
/// The image has a built-in wall area that we expose for alignment.
///
/// Image layout (1080x2340):
///   0% - 18.4%  → mint ceiling
///  18.4% - 25.6% → crown molding
///  25.6% - 71.0% → beige wall area
///  71.0% - 75.2% → baseboard
///  75.2% - 100%  → wooden floor
class BackgroundComponent extends PositionComponent {
  Sprite? _bgSprite;

  BackgroundComponent({
    Color ambientTint = const Color(kBgFallbackColor),
    required super.size,
  }) {
    position = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    try {
      final image = await Flame.images.load('homebackground.png');
      _bgSprite = Sprite(image);
    } catch (e) {
      // Fallback: no image, just show solid color
      _bgSprite = null;
    }
  }

  // Kept for API compatibility — no-op now since we use an image
  void updateAmbientTint(Color tint) {}

  /// Returns the wall area rect in screen coordinates based on the
  /// current component size. Used by PaintRollerGame to position the wall.
  Rect getWallRect() {
    final imgAspect = kBgImageWidth / kBgImageHeight;
    final screenAspect = size.x / size.y;

    double drawW, drawH, drawX, drawY;
    if (screenAspect < imgAspect) {
      drawW = size.x;
      drawH = size.x / imgAspect;
      drawX = 0;
      drawY = 0;
    } else {
      drawH = size.y;
      drawW = size.y * imgAspect;
      drawX = (size.x - drawW) / 2;
      drawY = 0;
    }

    final wallTop = drawY + drawH * kBgWallTopFraction;
    final wallBottom = drawY + drawH * kBgWallBottomFraction;
    final wallLeft = drawX + drawW * kBgWallLeftFraction;
    final wallRight = drawX + drawW * kBgWallRightFraction;

    return Rect.fromLTRB(wallLeft, wallTop, wallRight, wallBottom);
  }

  @override
  void render(Canvas canvas) {
    if (_bgSprite != null) {
      // Draw the image covering the full screen (cover mode)
      final imgAspect = kBgImageWidth / kBgImageHeight;
      final screenAspect = size.x / size.y;

      double drawW, drawH, drawX, drawY;
      if (screenAspect > imgAspect) {
        drawW = size.x;
        drawH = size.x / imgAspect;
        drawX = 0;
        drawY = 0;
      } else {
        drawH = size.y;
        drawW = size.y * imgAspect;
        drawX = (size.x - drawW) / 2;
        drawY = 0;
      }

      _bgSprite!.render(
        canvas,
        position: Vector2(drawX, drawY),
        size: Vector2(drawW, drawH),
      );
    } else {
      // Fallback solid color
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(kBgFallbackColor),
      );
    }
  }
}
