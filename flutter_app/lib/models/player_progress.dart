import 'dart:convert';
import 'upgrade.dart';
import 'house.dart';

class PlayerProgress {
  double cash;
  int stars;
  int prestigeLevel;
  HouseTier currentHouse;
  int currentRoom; // 0-4
  Map<UpgradeType, int> upgradeLevels;
  DateTime lastOnlineAt;
  int totalWallsPainted;
  double totalCashEarned;

  PlayerProgress({
    this.cash = 0,
    this.stars = 0,
    this.prestigeLevel = 0,
    this.currentHouse = HouseTier.apartment,
    this.currentRoom = 0,
    Map<UpgradeType, int>? upgradeLevels,
    DateTime? lastOnlineAt,
    this.totalWallsPainted = 0,
    this.totalCashEarned = 0,
  })  : upgradeLevels = upgradeLevels ?? {},
        lastOnlineAt = lastOnlineAt ?? DateTime.now();

  int getUpgradeLevel(UpgradeType type) => upgradeLevels[type] ?? 0;

  int get maxStrokes => 6 + getUpgradeLevel(UpgradeType.extraStroke);

  double get rollerWidthPercent => 0.15 + 0.02 * getUpgradeLevel(UpgradeType.widerRoller);

  double get rollerSpeedMultiplier {
    final reduction = 0.07 * getUpgradeLevel(UpgradeType.steadyHand);
    return 1.0 - reduction.clamp(0.0, 0.35);
  }

  double get cashPerTapMultiplier => 1.0 + 0.10 * getUpgradeLevel(UpgradeType.turboSpeed);

  double get idleIncomePerSecond => 2.0 * getUpgradeLevel(UpgradeType.autoPainter);

  double get starMultiplier => 1.0 + 0.10 * stars;

  double get marketplaceFeePercent => (5 - getUpgradeLevel(UpgradeType.brokerLicense)).toDouble().clamp(2.0, 5.0);

  bool get canPrestige {
    final house = HouseDefinition.getDefinition(currentHouse);
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

    HouseTier house = HouseTier.apartment;
    try {
      house = HouseTier.values.firstWhere((h) => h.name == json['currentHouse']);
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
