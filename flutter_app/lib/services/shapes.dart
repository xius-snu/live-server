import 'dart:math';
import 'package:flutter/material.dart';

/// A point with normalized coordinates (0.0 to 1.0), centered at (0.5, 0.5)
class NormalizedPoint {
  final double x, y;
  const NormalizedPoint(this.x, this.y);
}

/// Shape tier with associated color
enum ShapeTier {
  tier1(1, Color(0xFF00BFFF)),  // Deep Sky Blue
  tier2(2, Color(0xFF00FF7F)),  // Spring Green
  tier3(3, Color(0xFFDA70D6)),  // Orchid/Purple
  tier4(4, Color(0xFFFFD700));  // Gold

  final int level;
  final Color color;
  const ShapeTier(this.level, this.color);
}

/// A shape definition with normalized path points
class ShapeDefinition {
  final String name;
  final ShapeTier tier;
  final List<NormalizedPoint> path;

  const ShapeDefinition(this.name, this.tier, this.path);

  /// Convert normalized path to screen coordinates
  List<Offset> toScreenPath(Offset center, double size) {
    return path.map((p) {
      final dx = (p.x - 0.5) * size;
      final dy = (p.y - 0.5) * size;
      return Offset(center.dx + dx, center.dy + dy);
    }).toList();
  }

  /// Convert to Flutter Path for rendering
  Path toFlutterPath(Offset center, double size) {
    final screenPath = toScreenPath(center, size);
    final flutterPath = Path();
    if (screenPath.isEmpty) return flutterPath;

    flutterPath.moveTo(screenPath[0].dx, screenPath[0].dy);
    for (int i = 1; i < screenPath.length; i++) {
      flutterPath.lineTo(screenPath[i].dx, screenPath[i].dy);
    }
    return flutterPath;
  }
}

/// Progression state for weighted shape selection
class PlayerProgression {
  final Set<String> collectedShapes;
  final int affinityTier; // 1-4

  const PlayerProgression({
    required this.collectedShapes,
    required this.affinityTier,
  });

  bool hasAllTier1() {
    final tier1 = ShapeRegistry.getShapesByTier(ShapeTier.tier1);
    return tier1.every((s) => collectedShapes.contains(s));
  }

  bool hasAllTier2() {
    final tier2 = ShapeRegistry.getShapesByTier(ShapeTier.tier2);
    return tier2.every((s) => collectedShapes.contains(s));
  }

  bool hasAllTier3() {
    final tier3 = ShapeRegistry.getShapesByTier(ShapeTier.tier3);
    return tier3.every((s) => collectedShapes.contains(s));
  }
}

/// Registry of all available shapes organized by tier
class ShapeRegistry {
  static final Map<String, ShapeDefinition> _shapes = {
    // Tier 1 - Basic
    'Circle': _generateCircle(),
    'Triangle': _generateTriangle(),
    'Square': _generateSquare(),
    'Line': _generateLine(),

    // Tier 2 - Intermediate
    'Pentagon': _generatePentagon(),
    'Hexagon': _generateHexagon(),
    'Diamond': _generateDiamond(),
    'Trapezoid': _generateTrapezoid(),
    'Heart': _generateHeart(),

    // Tier 3 - Advanced
    'Lightning': _generateLightning(),
    'Mustache': _generateMustache(),

    // Tier 4 - Expert
    'Infinity': _generateInfinity(),
  };

  static ShapeDefinition? get(String name) => _shapes[name];

  static List<String> get availableShapes => _shapes.keys.toList();

  static List<String> getShapesByTier(ShapeTier tier) {
    return _shapes.entries
        .where((e) => e.value.tier == tier)
        .map((e) => e.key)
        .toList();
  }

  static Color getColorForShape(String name) {
    return _shapes[name]?.tier.color ?? Colors.white;
  }

  static ShapeTier? getTierForShape(String name) {
    return _shapes[name]?.tier;
  }

  /// Get tier weights based on player progression
  /// Returns map of tier level (1-4) to probability weight
  static Map<int, double> _getTierWeights(PlayerProgression progression) {
    if (progression.hasAllTier3()) {
      // Has all T1+T2+T3
      return {1: 0.15, 2: 0.25, 3: 0.35, 4: 0.25};
    } else if (progression.hasAllTier2()) {
      // Has all T1+T2
      return {1: 0.20, 2: 0.30, 3: 0.40, 4: 0.10};
    } else if (progression.hasAllTier1()) {
      // Has all T1
      return {1: 0.40, 2: 0.45, 3: 0.12, 4: 0.03};
    } else {
      // New player
      return {1: 0.70, 2: 0.25, 3: 0.05, 4: 0.0};
    }
  }

  /// Select a weighted random shape based on progression and affinity
  /// - 70% chance to get shape from affinity tier
  /// - 30% chance from other tiers
  /// - Tier appearance rates based on progression
  static String getWeightedRandomShape(PlayerProgression progression, {bool forceNonAffinity = false}) {
    final random = Random();
    final tierWeights = _getTierWeights(progression);

    // Determine if we use affinity or other tiers
    bool useAffinity = !forceNonAffinity && random.nextDouble() < 0.70;

    ShapeTier selectedTier;

    if (useAffinity) {
      // Use affinity tier directly
      selectedTier = ShapeTier.values.firstWhere((t) => t.level == progression.affinityTier);
    } else {
      // Weighted random from tier weights (excluding zero-weight tiers)
      double roll = random.nextDouble();
      double cumulative = 0;
      int selectedLevel = 1;

      for (final entry in tierWeights.entries) {
        cumulative += entry.value;
        if (roll < cumulative) {
          selectedLevel = entry.key;
          break;
        }
      }

      // If we rolled affinity tier in "other" mode, re-roll once
      if (!forceNonAffinity && selectedLevel == progression.affinityTier) {
        // Just pick a different tier
        final otherTiers = tierWeights.keys.where((t) => t != progression.affinityTier && tierWeights[t]! > 0).toList();
        if (otherTiers.isNotEmpty) {
          selectedLevel = otherTiers[random.nextInt(otherTiers.length)];
        }
      }

      selectedTier = ShapeTier.values.firstWhere((t) => t.level == selectedLevel);
    }

    // Get shapes from selected tier
    final shapesInTier = getShapesByTier(selectedTier);
    if (shapesInTier.isEmpty) {
      // Fallback to tier 1 if empty
      final tier1Shapes = getShapesByTier(ShapeTier.tier1);
      return tier1Shapes[random.nextInt(tier1Shapes.length)];
    }

    return shapesInTier[random.nextInt(shapesInTier.length)];
  }

  /// Get a guaranteed non-affinity shape (for Hot Streak bonus)
  static String getNonAffinityShape(PlayerProgression progression) {
    return getWeightedRandomShape(progression, forceNonAffinity: true);
  }

  /// Get a high-tier shape (Tier 3 or 4) for Bonus Round
  static String getHighTierShape() {
    final random = Random();
    final tier = random.nextDouble() < 0.6 ? ShapeTier.tier3 : ShapeTier.tier4;
    final shapes = getShapesByTier(tier);
    return shapes[random.nextInt(shapes.length)];
  }

  /// Get total shapes per tier for collection tracking
  static int getTotalShapesInTier(ShapeTier tier) {
    return getShapesByTier(tier).length;
  }

  // ============================================================
  // TIER 1 - Basic Shapes
  // ============================================================

  static ShapeDefinition _generateCircle() {
    final points = <NormalizedPoint>[];
    const numPoints = 64;
    const radius = 0.45;

    for (int i = 0; i < numPoints; i++) {
      final t = (i / numPoints) * 2 * pi;
      points.add(NormalizedPoint(
        0.5 + cos(t) * radius,
        0.5 + sin(t) * radius,
      ));
    }
    points.add(points[0]);

    return ShapeDefinition('Circle', ShapeTier.tier1, points);
  }

  static ShapeDefinition _generateTriangle() {
    final points = <NormalizedPoint>[];
    const radius = 0.45;

    final vertices = [
      NormalizedPoint(0.5, 0.5 - radius),
      NormalizedPoint(0.5 + radius * cos(pi / 6), 0.5 + radius * sin(pi / 6)),
      NormalizedPoint(0.5 - radius * cos(pi / 6), 0.5 + radius * sin(pi / 6)),
    ];

    const pointsPerEdge = 21;
    for (int edge = 0; edge < 3; edge++) {
      final start = vertices[edge];
      final end = vertices[(edge + 1) % 3];
      for (int i = 0; i < pointsPerEdge; i++) {
        final t = i / pointsPerEdge;
        points.add(NormalizedPoint(
          start.x + t * (end.x - start.x),
          start.y + t * (end.y - start.y),
        ));
      }
    }
    points.add(vertices[0]);

    return ShapeDefinition('Triangle', ShapeTier.tier1, points);
  }

  static ShapeDefinition _generateSquare() {
    final points = <NormalizedPoint>[];
    const halfSize = 0.4;

    final corners = [
      NormalizedPoint(0.5 - halfSize, 0.5 - halfSize),
      NormalizedPoint(0.5 + halfSize, 0.5 - halfSize),
      NormalizedPoint(0.5 + halfSize, 0.5 + halfSize),
      NormalizedPoint(0.5 - halfSize, 0.5 + halfSize),
    ];

    const pointsPerEdge = 16;
    for (int edge = 0; edge < 4; edge++) {
      final start = corners[edge];
      final end = corners[(edge + 1) % 4];
      for (int i = 0; i < pointsPerEdge; i++) {
        final t = i / pointsPerEdge;
        points.add(NormalizedPoint(
          start.x + t * (end.x - start.x),
          start.y + t * (end.y - start.y),
        ));
      }
    }
    points.add(corners[0]);

    return ShapeDefinition('Square', ShapeTier.tier1, points);
  }

  static ShapeDefinition _generateLine() {
    final points = <NormalizedPoint>[];
    const numPoints = 32;

    // Diagonal line from top-left to bottom-right
    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      points.add(NormalizedPoint(
        0.15 + t * 0.7,
        0.15 + t * 0.7,
      ));
    }

    return ShapeDefinition('Line', ShapeTier.tier1, points);
  }

  // ============================================================
  // TIER 2 - Intermediate Shapes
  // ============================================================

  static ShapeDefinition _generatePentagon() {
    final points = <NormalizedPoint>[];
    const radius = 0.45;
    const sides = 5;

    final vertices = <NormalizedPoint>[];
    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + (i / sides) * 2 * pi;
      vertices.add(NormalizedPoint(
        0.5 + cos(angle) * radius,
        0.5 + sin(angle) * radius,
      ));
    }

    const pointsPerEdge = 13;
    for (int edge = 0; edge < sides; edge++) {
      final start = vertices[edge];
      final end = vertices[(edge + 1) % sides];
      for (int i = 0; i < pointsPerEdge; i++) {
        final t = i / pointsPerEdge;
        points.add(NormalizedPoint(
          start.x + t * (end.x - start.x),
          start.y + t * (end.y - start.y),
        ));
      }
    }
    points.add(vertices[0]);

    return ShapeDefinition('Pentagon', ShapeTier.tier2, points);
  }

  static ShapeDefinition _generateHexagon() {
    final points = <NormalizedPoint>[];
    const radius = 0.45;
    const sides = 6;

    final vertices = <NormalizedPoint>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i / sides) * 2 * pi;
      vertices.add(NormalizedPoint(
        0.5 + cos(angle) * radius,
        0.5 + sin(angle) * radius,
      ));
    }

    const pointsPerEdge = 11;
    for (int edge = 0; edge < sides; edge++) {
      final start = vertices[edge];
      final end = vertices[(edge + 1) % sides];
      for (int i = 0; i < pointsPerEdge; i++) {
        final t = i / pointsPerEdge;
        points.add(NormalizedPoint(
          start.x + t * (end.x - start.x),
          start.y + t * (end.y - start.y),
        ));
      }
    }
    points.add(vertices[0]);

    return ShapeDefinition('Hexagon', ShapeTier.tier2, points);
  }

  static ShapeDefinition _generateDiamond() {
    final points = <NormalizedPoint>[];
    const halfWidth = 0.3;
    const halfHeight = 0.45;

    final corners = [
      NormalizedPoint(0.5, 0.5 - halfHeight),  // Top
      NormalizedPoint(0.5 + halfWidth, 0.5),   // Right
      NormalizedPoint(0.5, 0.5 + halfHeight),  // Bottom
      NormalizedPoint(0.5 - halfWidth, 0.5),   // Left
    ];

    const pointsPerEdge = 16;
    for (int edge = 0; edge < 4; edge++) {
      final start = corners[edge];
      final end = corners[(edge + 1) % 4];
      for (int i = 0; i < pointsPerEdge; i++) {
        final t = i / pointsPerEdge;
        points.add(NormalizedPoint(
          start.x + t * (end.x - start.x),
          start.y + t * (end.y - start.y),
        ));
      }
    }
    points.add(corners[0]);

    return ShapeDefinition('Diamond', ShapeTier.tier2, points);
  }

  static ShapeDefinition _generateTrapezoid() {
    final points = <NormalizedPoint>[];

    final corners = [
      NormalizedPoint(0.3, 0.25),   // Top-left
      NormalizedPoint(0.7, 0.25),   // Top-right
      NormalizedPoint(0.85, 0.75),  // Bottom-right
      NormalizedPoint(0.15, 0.75),  // Bottom-left
    ];

    const pointsPerEdge = 16;
    for (int edge = 0; edge < 4; edge++) {
      final start = corners[edge];
      final end = corners[(edge + 1) % 4];
      for (int i = 0; i < pointsPerEdge; i++) {
        final t = i / pointsPerEdge;
        points.add(NormalizedPoint(
          start.x + t * (end.x - start.x),
          start.y + t * (end.y - start.y),
        ));
      }
    }
    points.add(corners[0]);

    return ShapeDefinition('Trapezoid', ShapeTier.tier2, points);
  }

  static ShapeDefinition _generateHeart() {
    final points = <NormalizedPoint>[];
    const numPoints = 64;

    for (int i = 0; i <= numPoints; i++) {
      final t = (i / numPoints) * 2 * pi;
      // Heart parametric equation
      final x = 16 * pow(sin(t), 3);
      final y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t));
      points.add(NormalizedPoint(
        0.5 + x * 0.025,
        0.5 + y * 0.025,
      ));
    }

    return ShapeDefinition('Heart', ShapeTier.tier2, points);
  }

  // ============================================================
  // TIER 3 - Advanced Shapes
  // ============================================================

  static ShapeDefinition _generateLightning() {
    final points = <NormalizedPoint>[];

    // Simple zigzag lightning bolt - draw as one stroke top to bottom
    final zigzag = [
      NormalizedPoint(0.6, 0.1),   // Top
      NormalizedPoint(0.35, 0.45), // Zag left
      NormalizedPoint(0.55, 0.45), // Zig right
      NormalizedPoint(0.25, 0.9),  // Bottom point
    ];

    const pointsPerSegment = 16;
    for (int seg = 0; seg < zigzag.length - 1; seg++) {
      final start = zigzag[seg];
      final end = zigzag[seg + 1];
      for (int i = 0; i <= pointsPerSegment; i++) {
        final t = i / pointsPerSegment;
        points.add(NormalizedPoint(
          start.x + t * (end.x - start.x),
          start.y + t * (end.y - start.y),
        ));
      }
    }

    return ShapeDefinition('Lightning', ShapeTier.tier3, points);
  }

  static ShapeDefinition _generateMustache() {
    final points = <NormalizedPoint>[];
    const numPoints = 60;
    
    // Continuous outline of a handlebar mustache
    // Start center top -> right top curve -> right curl -> right bottom -> center bottom -> left bottom -> left curl -> left top curve
    
    // Center Top to Right Tip
    for (int i=0; i<=numPoints/2; i++) {
        final t = i/(numPoints/2);
        points.add(NormalizedPoint(
            0.5 + t * 0.4,
            0.45 - sin(t*pi)*0.1 // Arch up
        ));
    }
    
    // Right Curl down and back
    for (int i=0; i<=10; i++) {
        final t = i/10;
        points.add(NormalizedPoint(
            0.9 + sin(t*pi)*0.05,
            0.45 + t * 0.1
        ));
    }
    
    // Right Bottom to Center Bottom
    for (int i=0; i<=numPoints/2; i++) {
        final t = i/(numPoints/2);
        points.add(NormalizedPoint(
            0.9 - t * 0.4,
            0.55 + sin(t*pi)*0.05
        ));
    }

    // Center Bottom to Left Bottom
    for (int i=0; i<=numPoints/2; i++) {
        final t = i/(numPoints/2);
        points.add(NormalizedPoint(
            0.5 - t * 0.4,
            0.55 + sin(t*pi)*0.05
        ));
    }
    
    // Left Curl
    for (int i=0; i<=10; i++) {
        final t = i/10;
        points.add(NormalizedPoint(
            0.1 - sin(t*pi)*0.05,
            0.55 - t * 0.1
        ));
    }

     // Left Top back to Center
    for (int i=0; i<=numPoints/2; i++) {
        final t = i/(numPoints/2);
        points.add(NormalizedPoint(
            0.1 + t * 0.4,
            0.45 - sin((1-t)*pi)*0.1
        ));
    }

    return ShapeDefinition('Mustache', ShapeTier.tier3, points);
  }

  // ============================================================
  // TIER 4 - Expert Shapes
  // ============================================================

  static ShapeDefinition _generateInfinity() {
    final points = <NormalizedPoint>[];
    const numPoints = 64;

    // Lemniscate of Bernoulli (infinity symbol)
    for (int i = 0; i <= numPoints; i++) {
      final t = (i / numPoints) * 2 * pi;
      final scale = 0.35;
      final denom = 1 + sin(t) * sin(t);
      final x = scale * cos(t) / denom;
      final y = scale * sin(t) * cos(t) / denom;
      points.add(NormalizedPoint(0.5 + x, 0.5 + y));
    }

    return ShapeDefinition('Infinity', ShapeTier.tier4, points);
  }
}
