import 'package:flutter/material.dart';

/// The visual shape type drawn on the wall for each house.
enum PatternShape {
  square,       // Dirt House — dried mud patches
  plank,        // Shack — horizontal wooden boards
  circle,       // Cabin — log cross-section ends
  roundedStone, // Cottage — cobblestone wall
  brick,        // Townhouse — dense urban masonry
  diamond,      // Villa — decorative rotated tiles
  panel,        // Mansion — tall ornate wall panels
}

/// A discrete size option for a pattern shape.
class PatternSize {
  final double width;
  final double height;
  final double cornerRadius;
  const PatternSize(this.width, this.height, {this.cornerRadius = 0});
}

/// Full definition of a wall pattern for one house type.
class WallPatternDef {
  final PatternShape shape;
  final Color fillColor;
  final double strokeWidth;
  final List<PatternSize> sizes;
  final int minCount;
  final int maxCount;
  final double margin;

  const WallPatternDef({
    required this.shape,
    required this.fillColor,
    this.strokeWidth = 2.5,
    required this.sizes,
    required this.minCount,
    required this.maxCount,
    this.margin = 15.0,
  });

  /// All 7 pattern definitions, indexed by HouseDefinition.typeIndex (0–6).
  static const List<WallPatternDef> all = [
    // 0 — Dirt House: squares (dried mud patches)
    WallPatternDef(
      shape: PatternShape.square,
      fillColor: Color(0xFFA08858),
      sizes: [
        PatternSize(35, 35),
        PatternSize(50, 50),
        PatternSize(65, 65),
        PatternSize(80, 80),
      ],
      minCount: 8,
      maxCount: 12,
    ),
    // 1 — Shack: horizontal planks (wooden boards)
    WallPatternDef(
      shape: PatternShape.plank,
      fillColor: Color(0xFF8B7A58),
      sizes: [
        PatternSize(60, 25),
        PatternSize(80, 30),
        PatternSize(100, 35),
      ],
      minCount: 7,
      maxCount: 10,
    ),
    // 2 — Cabin: circles (log cross-section ends)
    WallPatternDef(
      shape: PatternShape.circle,
      fillColor: Color(0xFF8C7A58),
      sizes: [
        PatternSize(30, 30),   // radius 15
        PatternSize(44, 44),   // radius 22
        PatternSize(60, 60),   // radius 30
      ],
      minCount: 8,
      maxCount: 12,
    ),
    // 3 — Cottage: rounded stones (cobblestone)
    WallPatternDef(
      shape: PatternShape.roundedStone,
      fillColor: Color(0xFF708870),
      sizes: [
        PatternSize(40, 30, cornerRadius: 6),
        PatternSize(55, 40, cornerRadius: 8),
        PatternSize(70, 50, cornerRadius: 10),
      ],
      minCount: 9,
      maxCount: 13,
    ),
    // 4 — Townhouse: bricks (dense urban masonry)
    WallPatternDef(
      shape: PatternShape.brick,
      fillColor: Color(0xFF6C808A),
      sizes: [
        PatternSize(50, 25),
        PatternSize(65, 30),
      ],
      minCount: 12,
      maxCount: 16,
    ),
    // 5 — Villa: diamonds (decorative tiles, 45° rotated)
    WallPatternDef(
      shape: PatternShape.diamond,
      fillColor: Color(0xFF807060),
      sizes: [
        PatternSize(30, 30),   // diagonal 30
        PatternSize(40, 40),   // diagonal 40
        PatternSize(50, 50),   // diagonal 50
      ],
      minCount: 8,
      maxCount: 11,
    ),
    // 6 — Mansion: tall panels (ornate wall panels)
    WallPatternDef(
      shape: PatternShape.panel,
      fillColor: Color(0xFF786060),
      sizes: [
        PatternSize(35, 60, cornerRadius: 6),
        PatternSize(35, 75, cornerRadius: 6),
        PatternSize(45, 75, cornerRadius: 6),
        PatternSize(45, 90, cornerRadius: 6),
      ],
      minCount: 6,
      maxCount: 9,
    ),
  ];

  /// Look up the pattern definition for a given house type index (0–6).
  static WallPatternDef forHouseIndex(int typeIndex) {
    return all[typeIndex.clamp(0, all.length - 1)];
  }
}
