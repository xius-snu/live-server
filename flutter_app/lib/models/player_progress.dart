import 'dart:convert';
import 'upgrade.dart';
import 'house.dart';

class PlayerProgress {
  double cash;
  int stars;
  int prestigeLevel;
  HouseType currentHouse;
  int currentRoom; // 0-4
  Map<UpgradeType, int> upgradeLevels;
  DateTime lastOnlineAt;
  int totalWallsPainted;
  double totalCashEarned;

  PlayerProgress({
    this.cash = 0,
    this.stars = 0,
    this.prestigeLevel = 0,
    this.currentHouse = HouseType.dirtHouse,
    this.currentRoom = 0,
    Map<UpgradeType, int>? upgradeLevels,
    DateTime? lastOnlineAt,
    this.totalWallsPainted = 0,
    this.totalCashEarned = 0,
  })  : upgradeLevels = upgradeLevels ?? {},
        lastOnlineAt = lastOnlineAt ?? DateTime.now();

  int getUpgradeLevel(UpgradeType type) => upgradeLevels[type] ?? 0;

  /// Wall scale derived from prestige level (exponential growth curve).
  double get wallScale => HouseDefinition.wallScaleForPrestige(prestigeLevel);

  /// Base cash per wall derived from prestige level.
  double get baseCashPerWall => HouseDefinition.baseCashForPrestige(prestigeLevel);

  int get maxStrokes => 6 + getUpgradeLevel(UpgradeType.extraStroke);

  /// Roller width as fraction of wall. Base is 25% so early game is generous.
  /// The raw upgrade value is divided by wallScale so bigger houses make
  /// the roller feel smaller — you must upgrade to keep up.
  double get rollerWidthPercent {
    final rawWidth = 0.25 + 0.02 * getUpgradeLevel(UpgradeType.widerRoller);
    return (rawWidth / wallScale).clamp(0.05, 0.95);
  }

  /// Roller speed multiplier. More levels = slower (more precise).
  /// Diminishing returns: speed = 1 / (1 + 0.15 * level).
  double get rollerSpeedMultiplier {
    final level = getUpgradeLevel(UpgradeType.steadyHand);
    return 1.0 / (1.0 + 0.15 * level);
  }

  double get cashPerTapMultiplier => 1.0 + 0.10 * getUpgradeLevel(UpgradeType.turboSpeed);

  double get idleIncomePerSecond => 2.0 * getUpgradeLevel(UpgradeType.autoPainter);

  double get starMultiplier => 1.0 + 0.10 * stars;

  double get marketplaceFeePercent => (5 - getUpgradeLevel(UpgradeType.brokerLicense)).toDouble().clamp(2.0, 5.0);

  /// The current house definition.
  HouseDefinition get currentHouseDef => HouseDefinition.getByType(currentHouse);

  bool get canPrestige {
    final house = currentHouseDef;
    return currentRoom >= house.rooms.length - 1;
  }

  Map<String, dynamic> toJson() => {
        'cash': cash,
        'stars': stars,
        'prestigeLevel': prestigeLevel,
        'currentHouse': currentHouse.name,
        'currentRoom': currentRoom,
        'upgradeLevels': upgradeLevels.map((k, v) => MapEntry(k.name, v)),
        'lastOnlineAt': lastOnlineAt.toIso8601String(),
        'totalWallsPainted': totalWallsPainted,
        'totalCashEarned': totalCashEarned,
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

    HouseType house = HouseType.dirtHouse;
    try {
      house = HouseType.values.firstWhere((h) => h.name == json['currentHouse']);
    } catch (_) {}

    return PlayerProgress(
      cash: (json['cash'] as num?)?.toDouble() ?? 0,
      stars: json['stars'] as int? ?? 0,
      prestigeLevel: json['prestigeLevel'] as int? ?? 0,
      currentHouse: house,
      currentRoom: json['currentRoom'] as int? ?? 0,
      upgradeLevels: upgradeMap,
      lastOnlineAt: json['lastOnlineAt'] != null
          ? DateTime.tryParse(json['lastOnlineAt']) ?? DateTime.now()
          : DateTime.now(),
      totalWallsPainted: json['totalWallsPainted'] as int? ?? 0,
      totalCashEarned: (json['totalCashEarned'] as num?)?.toDouble() ?? 0,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory PlayerProgress.fromJsonString(String s) =>
      PlayerProgress.fromJson(json.decode(s));
}
