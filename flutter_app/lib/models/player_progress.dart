import 'dart:convert';
import 'upgrade.dart';
import 'house.dart';

class PlayerProgress {
  double cash;
  int gems;
  /// Global house level (1-based). Determines which house type + cycle level.
  int houseLevel;
  /// Roller upgrade level (0-based, like other upgrades).
  int rollerLevel;
  Map<UpgradeType, int> upgradeLevels;
  DateTime lastOnlineAt;
  int totalWallsPainted;
  double totalCashEarned;
  int streak; // consecutive walls with coverage bonus, tiered (7/10 max)
  double totalCoverageAccumulated; // sum of all wall coverages for averaging
  Set<String> ownedSkins;
  String equippedSkin;

  PlayerProgress({
    this.cash = 0,
    this.gems = 0,
    this.houseLevel = 1,
    this.rollerLevel = 0,
    Map<UpgradeType, int>? upgradeLevels,
    DateTime? lastOnlineAt,
    this.totalWallsPainted = 0,
    this.totalCashEarned = 0,
    this.streak = 0,
    this.totalCoverageAccumulated = 0,
    Set<String>? ownedSkins,
    this.equippedSkin = 'default',
  })  : upgradeLevels = upgradeLevels ?? {},
        lastOnlineAt = lastOnlineAt ?? DateTime.now(),
        ownedSkins = ownedSkins ?? {'default'};

  int getUpgradeLevel(UpgradeType type) => upgradeLevels[type] ?? 0;

  /// Current house definition based on house level.
  HouseDefinition get currentHouseDef =>
      HouseDefinition.getForHouseLevel(houseLevel);

  /// Current house type derived from house level.
  HouseType get currentHouse => currentHouseDef.type;

  /// Display name like "Cabin Lv. 2"
  String get houseDisplayName =>
      HouseDefinition.displayNameForHouseLevel(houseLevel);

  /// Wall scale for the current house level.
  double get wallScale =>
      HouseDefinition.wallScaleForHouseLevel(houseLevel);

  /// Base cash per wall derived from house level.
  double get baseCashPerWall =>
      HouseDefinition.baseCashForHouseLevel(houseLevel);

  int get maxStrokes => 6 + getUpgradeLevel(UpgradeType.extraStroke);

  /// Roller width as fraction of wall. Derived from roller level and house level.
  double get rollerWidthPercent =>
      HouseDefinition.rollerWidthPercent(rollerLevel, houseLevel);

  /// Roller speed multiplier. More levels = slower (more precise).
  double get rollerSpeedMultiplier {
    final level = getUpgradeLevel(UpgradeType.steadyHand);
    return 1.0 / (1.0 + 0.15 * level);
  }

  double get cashPerTapMultiplier => 1.0 + 0.10 * getUpgradeLevel(UpgradeType.turboSpeed);

  double get idleIncomePerSecond => 2.0 * getUpgradeLevel(UpgradeType.autoPainter);

  double get marketplaceFeePercent => (5 - getUpgradeLevel(UpgradeType.brokerLicense)).toDouble().clamp(2.0, 5.0);

  /// Cost to upgrade to the next house level.
  double get houseUpgradeCost =>
      HouseDefinition.houseUpgradeCost(houseLevel);

  /// Cost to upgrade roller to next level.
  double get rollerUpgradeCost =>
      HouseDefinition.rollerUpgradeCost(rollerLevel);

  /// Whether house can be upgraded (coupling constraint).
  bool get canUpgradeHouseLevel =>
      HouseDefinition.canUpgradeHouse(houseLevel, rollerLevel);

  /// Whether roller can be upgraded (coupling constraint).
  bool get canUpgradeRollerLevel =>
      HouseDefinition.canUpgradeRoller(rollerLevel, houseLevel);

  /// Average wall coverage across all painted walls.
  double get averageCoverage =>
      totalWallsPainted > 0 ? totalCoverageAccumulated / totalWallsPainted : 0.0;

  /// Cycle level display (e.g. "Lv. 2" part of "Cabin Lv. 2")
  int get houseCycleLevel => HouseDefinition.cycleLevelFor(houseLevel);

  Map<String, dynamic> toJson() => {
        'cash': cash,
        'gems': gems,
        'houseLevel': houseLevel,
        'rollerLevel': rollerLevel,
        'upgradeLevels': upgradeLevels.map((k, v) => MapEntry(k.name, v)),
        'lastOnlineAt': lastOnlineAt.toIso8601String(),
        'totalWallsPainted': totalWallsPainted,
        'totalCashEarned': totalCashEarned,
        'streak': streak,
        'totalCoverageAccumulated': totalCoverageAccumulated,
        'ownedSkins': ownedSkins.toList(),
        'equippedSkin': equippedSkin,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final upgradeMap = <UpgradeType, int>{};
    if (json['upgradeLevels'] != null) {
      final raw = json['upgradeLevels'] as Map<String, dynamic>;
      for (final entry in raw.entries) {
        try {
          final type = UpgradeType.values.firstWhere((t) => t.name == entry.key);
          upgradeMap[type] = entry.value as int;
        } catch (_) {}
      }
    }

    // Migration: convert old prestige/houseUpgradeLevel to new houseLevel
    int houseLevel = json['houseLevel'] as int? ?? 1;
    if (houseLevel < 1) {
      // Migrate from old system: use houseUpgradeLevel or prestigeLevel
      final oldPrestige = json['prestigeLevel'] as int? ?? 0;
      final oldHouseUpgrade = json['houseUpgradeLevel'] as int? ?? oldPrestige;
      houseLevel = (oldHouseUpgrade + 1).clamp(1, 9999);
    }

    // Migration: convert old widerRoller upgrade level to rollerLevel
    int rollerLevel = json['rollerLevel'] as int? ?? 0;
    if (json['rollerLevel'] == null && upgradeMap.containsKey(UpgradeType.widerRoller)) {
      rollerLevel = upgradeMap[UpgradeType.widerRoller] ?? 0;
      upgradeMap.remove(UpgradeType.widerRoller);
    }

    return PlayerProgress(
      cash: (json['cash'] as num?)?.toDouble() ?? 0,
      gems: json['gems'] as int? ?? json['stars'] as int? ?? 0,
      houseLevel: houseLevel,
      rollerLevel: rollerLevel,
      upgradeLevels: upgradeMap,
      lastOnlineAt: json['lastOnlineAt'] != null
          ? DateTime.tryParse(json['lastOnlineAt']) ?? DateTime.now()
          : DateTime.now(),
      totalWallsPainted: json['totalWallsPainted'] as int? ?? 0,
      totalCashEarned: (json['totalCashEarned'] as num?)?.toDouble() ?? 0,
      streak: json['streak'] as int? ?? 0,
      totalCoverageAccumulated: (json['totalCoverageAccumulated'] as num?)?.toDouble() ?? 0,
      ownedSkins: json['ownedSkins'] != null
          ? Set<String>.from(json['ownedSkins'] as List)
          : {'default'},
      equippedSkin: json['equippedSkin'] as String? ?? 'default',
    );
  }

  String toJsonString() => json.encode(toJson());

  factory PlayerProgress.fromJsonString(String s) =>
      PlayerProgress.fromJson(json.decode(s));
}
