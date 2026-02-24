import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../wall_pattern.dart';

/// Bright, cartoonish wall with procedural dirt spots and
/// house-type-specific decorative pattern shapes.
class WallComponent extends PositionComponent {
  Color wallColor;
  Color dirtColor;
  Color paintColor;
  Random _rng = Random(42);

  // Simple dirt blobs (soft, round, few)
  late List<_DirtBlob> _dirtBlobs;

  // Decorative pattern shapes (house-type specific)
  late List<_PatternPlacement> _patternShapes;

  // House tier hint (higher = cleaner wall)
  int houseTier;

  // Cycle level (Dirt House I = 1, Dirt House II = 2, etc.)
  int cycleLevel;

  // Seed that changes each wall/round for pattern variation
  int _wallSeed = 0;

  WallComponent({
    required this.wallColor,
    required this.dirtColor,
    required this.paintColor,
    this.houseTier = 0,
    this.cycleLevel = 1,
    super.position,
    super.size,
  });

  @override
  void onLoad() {
    super.onLoad();
    _regenerateAll();
  }

  void _regenerateAll() {
    _rng = Random(wallColor.value ^ dirtColor.value ^ _wallSeed);
    _generateDirtBlobs();
    _generatePatternShapes();
  }

  void _generateDirtBlobs() {
    // Fewer blobs for higher-tier houses. Keep them large and soft.
    final count = max(3, 12 - houseTier * 2);
    const margin = 12.0;
    _dirtBlobs = List.generate(count, (_) {
      final radius = 8.0 + _rng.nextDouble() * 18.0;
      return _DirtBlob(
        x: margin + _rng.nextDouble() * (size.x - margin * 2),
        y: margin + _rng.nextDouble() * (size.y - margin * 2),
        radius: radius,
        opacity: 0.06 + _rng.nextDouble() * 0.10,
      );
    });
  }

  void _generatePatternShapes() {
    final patternDef = WallPatternDef.forHouseIndex(houseTier);
    // Number of decorations = cycle level (Dirt House I = 1, II = 2, etc.)
    final targetCount = max(1, cycleLevel);
    final margin = patternDef.margin;

    final usableW = size.x - margin * 2;
    final usableH = size.y - margin * 2;
    if (usableW <= 0 || usableH <= 0) {
      _patternShapes = [];
      return;
    }

    // Use the median size from the pattern def as the base size
    final baseSizeOpt = patternDef.sizes[patternDef.sizes.length ~/ 2];

    // Try placing at scale 1.0 first; if not all fit, shrink and retry
    double scale = 1.0;
    List<_PatternPlacement> placed = [];

    for (int attempt = 0; attempt < 6; attempt++) {
      placed = _tryPlaceShapes(
        targetCount: targetCount,
        patternDef: patternDef,
        baseSizeOpt: baseSizeOpt,
        scale: scale,
        margin: margin,
        usableW: usableW,
        usableH: usableH,
      );
      if (placed.length >= targetCount) break;
      // Shrink by 15% each attempt
      scale *= 0.85;
    }

    _patternShapes = placed;
  }

  /// Attempt to place [targetCount] shapes at the given [scale].
  /// Returns the placed shapes (may be fewer than target if they don't fit).
  List<_PatternPlacement> _tryPlaceShapes({
    required int targetCount,
    required WallPatternDef patternDef,
    required PatternSize baseSizeOpt,
    required double scale,
    required double margin,
    required double usableW,
    required double usableH,
  }) {
    // Re-seed RNG consistently so shrink retries produce similar layouts
    final placementRng = Random(wallColor.value ^ dirtColor.value ^ _wallSeed ^ 0xABCD);

    // --- Grid-jitter placement for even spread ---
    final aspect = usableW / usableH;
    int cols = sqrt(targetCount * aspect).round().clamp(1, targetCount);
    int rows = (targetCount / cols).ceil().clamp(1, targetCount);
    while (cols * rows < targetCount) {
      cols++;
    }

    final cellW = usableW / cols;
    final cellH = usableH / rows;

    // Build shuffled cell list
    final allCells = <int>[];
    for (int i = 0; i < cols * rows; i++) {
      allCells.add(i);
    }
    for (int i = allCells.length - 1; i > 0; i--) {
      final j = placementRng.nextInt(i + 1);
      final tmp = allCells[i];
      allCells[i] = allCells[j];
      allCells[j] = tmp;
    }
    final selectedCells = allCells.take(targetCount).toList();

    final placed = <_PatternPlacement>[];

    for (final cellIdx in selectedCells) {
      final col = cellIdx % cols;
      final row = cellIdx ~/ cols;

      // Pick a random size from the available sizes, then apply scale
      final sizeOpt = patternDef.sizes[placementRng.nextInt(patternDef.sizes.length)];
      final w = sizeOpt.width * scale;
      final h = sizeOpt.height * scale;
      final cr = sizeOpt.cornerRadius * scale;

      final isDiamond = patternDef.shape == PatternShape.diamond;
      final bboxW = isDiamond ? w * 0.707 + h * 0.707 : w;
      final bboxH = isDiamond ? w * 0.707 + h * 0.707 : h;

      // Cell center + jitter
      final cellCx = margin + (col + 0.5) * cellW;
      final cellCy = margin + (row + 0.5) * cellH;
      final jitterX = ((placementRng.nextDouble() - 0.5) * cellW * 0.8);
      final jitterY = ((placementRng.nextDouble() - 0.5) * cellH * 0.8);

      final cx = (cellCx + jitterX).clamp(margin + bboxW / 2, size.x - margin - bboxW / 2);
      final cy = (cellCy + jitterY).clamp(margin + bboxH / 2, size.y - margin - bboxH / 2);

      // Reject overlaps
      const gap = 4.0;
      var overlaps = false;
      for (final existing in placed) {
        if ((cx - existing.cx).abs() < (bboxW + existing.bboxW) / 2 + gap &&
            (cy - existing.cy).abs() < (bboxH + existing.bboxH) / 2 + gap) {
          overlaps = true;
          break;
        }
      }
      if (overlaps) continue;

      placed.add(_PatternPlacement(
        cx: cx,
        cy: cy,
        width: w,
        height: h,
        bboxW: bboxW,
        bboxH: bboxH,
        cornerRadius: cr,
      ));
    }

    return placed;
  }

  void _renderPatternShapes(Canvas canvas) {
    if (_patternShapes.isEmpty) return;

    final patternDef = WallPatternDef.forHouseIndex(houseTier);

    final fillPaint = Paint()..color = patternDef.fillColor;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = patternDef.strokeWidth;
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final shape in _patternShapes) {
      canvas.save();
      canvas.translate(shape.cx, shape.cy);

      switch (patternDef.shape) {
        case PatternShape.square:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: shape.width,
            height: shape.height,
          );
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, strokePaint);
          // Top-edge highlight
          canvas.drawLine(
            rect.topLeft + const Offset(1, 1),
            rect.topRight + const Offset(-1, 1),
            highlightPaint,
          );
          break;

        case PatternShape.plank:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: shape.width,
            height: shape.height,
          );
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, strokePaint);
          // Top-edge highlight
          canvas.drawLine(
            rect.topLeft + const Offset(1, 1),
            rect.topRight + const Offset(-1, 1),
            highlightPaint,
          );
          break;

        case PatternShape.circle:
          final r = shape.width / 2;
          canvas.drawCircle(Offset.zero, r, fillPaint);
          canvas.drawCircle(Offset.zero, r, strokePaint);
          // Inner ring for log cross-section effect
          final innerRingPaint = Paint()
            ..color = patternDef.fillColor
                .withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          canvas.drawCircle(Offset.zero, r * 0.6, innerRingPaint);
          // Small center dot
          canvas.drawCircle(
            Offset.zero,
            r * 0.15,
            Paint()..color = patternDef.fillColor.withOpacity(0.5),
          );
          break;

        case PatternShape.roundedStone:
          final rrect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: shape.width,
              height: shape.height,
            ),
            Radius.circular(shape.cornerRadius),
          );
          canvas.drawRRect(rrect, fillPaint);
          canvas.drawRRect(rrect, strokePaint);
          // Top-edge highlight
          final stoneHalfW = shape.width / 2 - shape.cornerRadius;
          final stoneTopY = -shape.height / 2 + 1.5;
          canvas.drawLine(
            Offset(-stoneHalfW, stoneTopY),
            Offset(stoneHalfW, stoneTopY),
            highlightPaint,
          );
          break;

        case PatternShape.brick:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: shape.width,
            height: shape.height,
          );
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, strokePaint);
          // Top-edge highlight
          canvas.drawLine(
            rect.topLeft + const Offset(1, 1),
            rect.topRight + const Offset(-1, 1),
            highlightPaint,
          );
          break;

        case PatternShape.diamond:
          // Rotate 45° to make a diamond
          canvas.rotate(pi / 4);
          final half = shape.width / 2;
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: half * 1.0,
            height: half * 1.0,
          );
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, strokePaint);
          // Top-edge highlight (in rotated space)
          canvas.drawLine(
            rect.topLeft + const Offset(1, 1),
            rect.topRight + const Offset(-1, 1),
            highlightPaint,
          );
          break;

        case PatternShape.panel:
          final rrect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: shape.width,
              height: shape.height,
            ),
            Radius.circular(shape.cornerRadius),
          );
          canvas.drawRRect(rrect, fillPaint);
          canvas.drawRRect(rrect, strokePaint);
          // Inner ornate border
          if (shape.width > 12 && shape.height > 16) {
            final innerRrect = RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: shape.width - 8,
                height: shape.height - 8,
              ),
              Radius.circular(max(0, shape.cornerRadius - 2)),
            );
            canvas.drawRRect(
              innerRrect,
              Paint()
                ..color = Colors.white.withOpacity(0.08)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0,
            );
          }
          break;
      }

      canvas.restore();
    }
  }

  void updateColors(Color wall, Color dirt, Color paint) {
    wallColor = wall;
    dirtColor = dirt;
    paintColor = paint;
    _regenerateAll();
  }

  void updateHouseTier(int tier, {int? level}) {
    houseTier = tier;
    if (level != null) cycleLevel = level;
    _regenerateAll();
  }

  /// Update the random seed and regenerate all wall details.
  /// Call this each round so patterns vary between walls.
  void updateSeed(int seed) {
    _wallSeed = seed;
    _regenerateAll();
  }

  @override
  void render(Canvas canvas) {
    final wallRect = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.save();
    canvas.clipRect(wallRect);

    // === 1. Base wall color — solid, bright ===
    canvas.drawRect(wallRect, Paint()..color = wallColor);

    // === 2. Subtle vertical gradient for depth (lighter top, slightly darker bottom) ===
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.06),
          Colors.transparent,
          Colors.black.withOpacity(0.04),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(wallRect);
    canvas.drawRect(wallRect, gradientPaint);

    // === 3. Soft dirt blobs (large, blurry circles) ===
    for (final blob in _dirtBlobs) {
      final blobPaint = Paint()
        ..color = dirtColor.withOpacity(blob.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(
        Offset(blob.x, blob.y),
        blob.radius,
        blobPaint,
      );
    }

    // === 4. Decorative pattern shapes (house-type specific) ===
    _renderPatternShapes(canvas);

    // === 5. Gentle top-left light highlight ===
    final lightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.5),
        radius: 1.3,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(wallRect);
    canvas.drawRect(wallRect, lightPaint);

    canvas.restore();
  }
}

// --- Data classes ---

class _DirtBlob {
  final double x, y, radius, opacity;
  const _DirtBlob({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}

class _PatternPlacement {
  final double cx, cy;       // Center position
  final double width, height; // Shape size
  final double bboxW, bboxH; // Axis-aligned bounding box (for overlap checks)
  final double cornerRadius;
  const _PatternPlacement({
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
    required this.bboxW,
    required this.bboxH,
    this.cornerRadius = 0,
  });
}
