import 'dart:math';
import 'package:flutter/material.dart';

/// 7 house types that cycle infinitely with increasing levels.
/// Each house type has a distinct wall color and a base wall scale.
/// Progression: Lv.1 Dirt House -> Shack -> ... -> Mansion -> Lv.2 Dirt House -> ...
enum HouseType {
  dirtHouse,
  shack,
  cabin,
  cottage,
  townhouse,
  villa,
  mansion,
}

class RoomDefinition {
  final String name;
  final Color wallColor;
  final Color dirtColor;
  final Color paintColor;

  const RoomDefinition({
    required this.name,
    required this.wallColor,
    required this.dirtColor,
    required this.paintColor,
  });
}

class HouseDefinition {
  final HouseType type;
  final String name;
  final String icon;
  /// Base wall scale for this house type (before level multiplier).
  final double baseWallScale;
  /// Index 0-6 within the cycle.
  final int typeIndex;
  final RoomDefinition room;
  /// Border color for the wall frame.
  final Color borderColor;

  const HouseDefinition({
    required this.type,
    required this.name,
    required this.icon,
    required this.baseWallScale,
    required this.typeIndex,
    required this.room,
    required this.borderColor,
  });

  /// Display name with Roman numeral cycle level, e.g. "Townhouse II"
  String displayName(int cycleLevel) => '$name ${toRoman(cycleLevel)}';

  /// Wall scale for a given cycle level (kept for reference but not used
  /// for actual wall sizing — use wallScaleForHouseLevel instead).
  double wallScaleForLevel(int level) {
    return baseWallScale * (1.0 + 0.12 * (level - 1));
  }

  /// Convert integer to Roman numeral string.
  static String toRoman(int n) {
    if (n <= 0) return '$n';
    final vals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    final syms = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    final buf = StringBuffer();
    var rem = n;
    for (int i = 0; i < vals.length; i++) {
      while (rem >= vals[i]) {
        buf.write(syms[i]);
        rem -= vals[i];
      }
    }
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // 7 house types, each with distinct wall colors and increasing base scale.
  // ---------------------------------------------------------------------------
  static const List<HouseDefinition> all = [
    HouseDefinition(
      type: HouseType.dirtHouse,
      name: 'Dirt House',
      icon: '\u{1F3DA}\u{FE0F}',
      baseWallScale: 1.0,
      typeIndex: 0,
      borderColor: Color(0xFFA08858),
      room: RoomDefinition(
        name: 'Mud Room',
        wallColor: Color(0xFFC4A87A),
        dirtColor: Color(0xFFA08858),
        paintColor: Color(0xFFF5C842),
      ),
    ),
    HouseDefinition(
      type: HouseType.shack,
      name: 'Shack',
      icon: '\u{1FAB5}',
      baseWallScale: 1.15,
      typeIndex: 1,
      borderColor: Color(0xFF9A8A68),
      room: RoomDefinition(
        name: 'Main Room',
        wallColor: Color(0xFFB8A888),
        dirtColor: Color(0xFF9A8A68),
        paintColor: Color(0xFFFF6B35),
      ),
    ),
    HouseDefinition(
      type: HouseType.cabin,
      name: 'Cabin',
      icon: '\u{1F3E0}',
      baseWallScale: 1.3,
      typeIndex: 2,
      borderColor: Color(0xFF9C8A68),
      room: RoomDefinition(
        name: 'Living Area',
        wallColor: Color(0xFFBCAA88),
        dirtColor: Color(0xFF9C8A68),
        paintColor: Color(0xFF38BDF8),
      ),
    ),
    HouseDefinition(
      type: HouseType.cottage,
      name: 'Cottage',
      icon: '\u{26FA}',
      baseWallScale: 1.5,
      typeIndex: 3,
      borderColor: Color(0xFF809880),
      room: RoomDefinition(
        name: 'Parlor',
        wallColor: Color(0xFFA0B8A0),
        dirtColor: Color(0xFF809880),
        paintColor: Color(0xFF4ADE80),
      ),
    ),
    HouseDefinition(
      type: HouseType.townhouse,
      name: 'Townhouse',
      icon: '\u{1F3D8}\u{FE0F}',
      baseWallScale: 1.7,
      typeIndex: 4,
      borderColor: Color(0xFF7C9098),
      room: RoomDefinition(
        name: 'Foyer',
        wallColor: Color(0xFF9CB0B8),
        dirtColor: Color(0xFF7C9098),
        paintColor: Color(0xFF3B82F6),
      ),
    ),
    HouseDefinition(
      type: HouseType.villa,
      name: 'Villa',
      icon: '\u{1F3E8}',
      baseWallScale: 1.95,
      typeIndex: 5,
      borderColor: Color(0xFF908070),
      room: RoomDefinition(
        name: 'Grand Hall',
        wallColor: Color(0xFFB0A090),
        dirtColor: Color(0xFF908070),
        paintColor: Color(0xFFEC4899),
      ),
    ),
    HouseDefinition(
      type: HouseType.mansion,
      name: 'Mansion',
      icon: '\u{1F3F0}',
      baseWallScale: 2.2,
      typeIndex: 6,
      borderColor: Color(0xFF887070),
      room: RoomDefinition(
        name: 'Ballroom',
        wallColor: Color(0xFFA89090),
        dirtColor: Color(0xFF887070),
        paintColor: Color(0xFFA855F7),
      ),
    ),
  ];

  static HouseDefinition getByType(HouseType type) {
    return all.firstWhere((h) => h.type == type);
  }

  /// Get the house definition for a given global house level (1-based).
  /// Level 1-7 = Lv.1 of each type, Level 8-14 = Lv.2, etc.
  static HouseDefinition getForHouseLevel(int houseLevel) {
    final idx = (houseLevel - 1) % all.length;
    return all[idx];
  }

  /// Get the cycle level (Lv. N) for a given global house level.
  /// House level 1-7 = Lv.1, 8-14 = Lv.2, etc.
  static int cycleLevelFor(int houseLevel) {
    return ((houseLevel - 1) ~/ all.length) + 1;
  }

  /// Get the wall scale for a given global house level.
  /// Monotonically increasing: every house level is strictly larger than
  /// the previous. Growth = 5% per level compounding.
  /// Level 1 = 1.0, Level 7 (Mansion I) ≈ 1.34, Level 8 (Dirt House II) ≈ 1.41, etc.
  static double wallScaleForHouseLevel(int houseLevel) {
    return 1.0 * _pow(1.05, houseLevel - 1);
  }


  /// Get the display name for a given global house level, e.g. "Cabin Lv. 2"
  static String displayNameForHouseLevel(int houseLevel) {
    final def = getForHouseLevel(houseLevel);
    final cycleLevel = cycleLevelFor(houseLevel);
    return def.displayName(cycleLevel);
  }

  /// Base cash per wall scales with house level.
  /// Higher house level = more cash reward.
  static double baseCashForHouseLevel(int houseLevel) {
    return 10.0 * (1.0 + 0.3 * (houseLevel - 1));
  }

  /// Cost to upgrade to the next house level.
  /// Gentle exponential: base 40, multiplier 1.35x per level.
  static double houseUpgradeCost(int currentHouseLevel) {
    return (40.0 * _pow(1.35, currentHouseLevel - 1)).roundToDouble();
  }

  /// Cost to upgrade roller size to the next level.
  /// Gentle exponential: base 30, multiplier 1.30x per level.
  static double rollerUpgradeCost(int currentRollerLevel) {
    return (30.0 * _pow(1.30, currentRollerLevel)).roundToDouble();
  }

  static double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  /// Max allowed level difference between house level and roller level.
  static const int maxLevelDiff = 10;

  /// Check if player can upgrade house level given current roller level.
  static bool canUpgradeHouse(int currentHouseLevel, int rollerLevel) {
    return (currentHouseLevel + 1) - rollerLevel <= maxLevelDiff;
  }

  /// Check if player can upgrade roller level given current house level.
  static bool canUpgradeRoller(int rollerLevel, int houseLevel) {
    return (rollerLevel + 1) - houseLevel <= maxLevelDiff;
  }

  /// Roller width fraction for a given roller level relative to a house level.
  /// The roller size is designed so that at equal levels, you cover roughly
  /// 25% of the wall per stroke — making 6 strokes give ~80-90% coverage
  /// with good placement (comfortable but not trivial).
  ///
  /// Formula: base 0.25 raw width, +1.5% per roller level, divided by wall scale.
  static double rollerWidthPercent(int rollerLevel, int houseLevel) {
    final rawWidth = 0.25 + 0.015 * rollerLevel;
    final wallScale = wallScaleForHouseLevel(houseLevel);
    return (rawWidth / wallScale).clamp(0.05, 0.95);
  }

  // ---------------------------------------------------------------------------
  // Absolute size display (meters). The base wall (scale 1.0) = 10m².
  // Wall area scales linearly with wallScale. Roller width in meters is
  // derived from the fraction of wall width it covers.
  // ---------------------------------------------------------------------------

  /// Base wall width in meters at scale 1.0.
  static const double _baseWallWidthM = 3.2; // ~3.2m wide
  /// Base wall height in meters at scale 1.0.
  static const double _baseWallHeightM = 3.0; // ~3.0m tall

  /// Absolute wall area in m² for a given house level.
  static double wallAreaM2(int houseLevel) {
    final scale = wallScaleForHouseLevel(houseLevel);
    return _baseWallWidthM * scale * _baseWallHeightM * scale;
  }

  /// Display wall area, e.g. "10m²", "46m²".
  static String wallAreaDisplay(int houseLevel) {
    final area = wallAreaM2(houseLevel);
    return '${area.round()}m\u00B2';
  }

  /// Absolute roller width in meters for a given roller level + house level.
  static double rollerWidthM(int rollerLevel, int houseLevel) {
    final scale = wallScaleForHouseLevel(houseLevel);
    final wallWidth = _baseWallWidthM * scale;
    final fraction = rollerWidthPercent(rollerLevel, houseLevel);
    return wallWidth * fraction;
  }

  /// Display roller width, e.g. "0.80m".
  static String rollerWidthDisplay(int rollerLevel, int houseLevel) {
    final m = rollerWidthM(rollerLevel, houseLevel);
    return '${m.toStringAsFixed(2)}m';
  }

  /// Weights for up to 7 most-recent tiers.
  /// Index 0 = most recently unlocked (highest prob), index 6 = 7th back.
  /// Sum = 100 when all 7 are used.
  static const List<int> _tierWeights = [18, 17, 16, 14, 13, 12, 10];

  /// Pick a random house level from the most-recent tier pool.
  /// Returns a houseLevel in [max(1, maxHouseLevel-6) .. maxHouseLevel].
  static int randomWeightedHouseLevel(int maxHouseLevel, Random rng) {
    if (maxHouseLevel <= 1) return 1;

    // Build pool: up to 7 most recent levels
    final poolSize = maxHouseLevel.clamp(1, _tierWeights.length);
    final startLevel = maxHouseLevel - poolSize + 1; // inclusive

    // Sum weights for this pool size
    int totalWeight = 0;
    for (int i = 0; i < poolSize; i++) {
      totalWeight += _tierWeights[i];
    }

    // Roll
    int roll = rng.nextInt(totalWeight);
    for (int i = 0; i < poolSize; i++) {
      roll -= _tierWeights[i];
      if (roll < 0) {
        // i=0 → most recent (maxHouseLevel), i=1 → second most recent, etc.
        return maxHouseLevel - i;
      }
    }

    // Fallback (shouldn't reach here)
    return startLevel;
  }
}
