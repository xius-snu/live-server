import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_progress.dart';
import '../models/upgrade.dart';
import '../models/house.dart';

/// Definition for a purchasable roller skin.
class RollerSkinDef {
  final String id;
  final String name;
  final String asset; // filename in assets/images/rollers/
  final double price; // coin cost, 0 = free
  final Color paintColor; // unique paint color for this roller

  const RollerSkinDef({
    required this.id,
    required this.name,
    required this.asset,
    required this.price,
    required this.paintColor,
  });
}

class GameService extends ChangeNotifier {
  PlayerProgress _progress = PlayerProgress();
  bool _initialized = false;

  PlayerProgress get progress => _progress;
  bool get initialized => _initialized;

  /// All roller skins in order (least → most cool / expensive).
  static const List<RollerSkinDef> rollerSkinDefs = [
    RollerSkinDef(id: 'default', name: 'Default', asset: 'default.png', price: 0, paintColor: Color(0xFFFF3B30)),       // bright red
    RollerSkinDef(id: 'pudding', name: 'Pudding', asset: 'pudding.png', price: 500, paintColor: Color(0xFFFF9500)),     // vivid orange
    RollerSkinDef(id: 'pancake', name: 'Pancake', asset: 'pancake.png', price: 2000, paintColor: Color(0xFFFF2D90)),    // hot pink
    RollerSkinDef(id: 'bunny', name: 'Bunny', asset: 'bunny.png', price: 8000, paintColor: Color(0xFF5856D6)),          // electric purple
    RollerSkinDef(id: 'kitty', name: 'Kitty', asset: 'kitty.png', price: 25000, paintColor: Color(0xFF30D158)),         // neon green
    RollerSkinDef(id: 'money', name: 'Money', asset: 'money.png', price: 80000, paintColor: Color(0xFFFFD700)),         // gold
  ];

  // Convenience getters
  double get cash => _progress.cash;
  int get gems => _progress.gems;
  int get houseLevel => _progress.houseLevel;
  int get rollerLevel => _progress.rollerLevel;
  HouseType get currentHouse => _progress.currentHouse;
  int get maxStrokes => _progress.maxStrokes;
  double get rollerWidthPercent => _progress.rollerWidthPercent;
  double get rollerSpeedMultiplier => _progress.rollerSpeedMultiplier;
  int get streak => _progress.streak;
  String get equippedSkin => _progress.equippedSkin;
  Set<String> get ownedSkins => _progress.ownedSkins;
  Color get equippedPaintColor =>
      rollerSkinDefs.firstWhere((s) => s.id == equippedSkin,
          orElse: () => rollerSkinDefs.first).paintColor;

  HouseDefinition get currentHouseDef => _progress.currentHouseDef;
  RoomDefinition get currentRoomDef => currentHouseDef.room;

  Future<void> init() async {
    await _loadLocally();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('player_progress');
    if (json != null) {
      _progress = PlayerProgress.fromJsonString(json);
    }
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_progress', _progress.toJsonString());
  }

  /// Coverage bonus multiplier for high coverage rounds.
  static double coverageBonus(double coverage) {
    if (coverage >= 1.0) return 3.0;   // 100% = 3x
    if (coverage >= 0.95) return 2.0;  // 95%+ = 2x
    if (coverage >= 0.90) return 1.5;  // 90%+ = 1.5x
    return 1.0;
  }

  /// Streak cash bonus multiplier. 5% per streak level, uncapped.
  static double streakBonusMultiplier(int streak) {
    return 0.05 * streak;
  }

  /// Complete a paint round. Returns (basePayout, streakBonus).
  (double payout, double streakBonus) completePaintRound(double coverage) {
    final baseCash = _progress.baseCashPerWall;

    final coverageFactor = pow(coverage.clamp(0.0, 1.0), 1.5).toDouble();
    final bonus = coverageBonus(coverage.clamp(0.0, 1.0));

    final basePayout = baseCash *
        coverageFactor *
        bonus *
        _progress.cashPerTapMultiplier;

    // Tiered streak system (max 10):
    // - 2x+ (GREAT/PERFECT): advances up to streak 10
    // - 1.5x (NICE): advances up to streak 7, drops to 7 if above
    // - No bonus: resets to 0
    final oldStreak = _progress.streak;
    if (bonus >= 2.0) {
      _progress.streak = (oldStreak + 1).clamp(0, 10);
    } else if (bonus >= 1.5) {
      if (oldStreak < 7) {
        _progress.streak = oldStreak + 1;
      } else {
        _progress.streak = 7;
      }
    } else {
      _progress.streak = 0;
    }

    final streakCashBonus = basePayout * streakBonusMultiplier(_progress.streak);
    final totalPayout = basePayout + streakCashBonus;

    _progress.cash += totalPayout;
    _progress.totalCashEarned += totalPayout;
    _progress.totalCoverageAccumulated += coverage.clamp(0.0, 1.0);
    _progress.totalWallsPainted++;
    _progress.lastOnlineAt = DateTime.now();

    _saveLocally();
    notifyListeners();
    return (basePayout, streakCashBonus);
  }

  /// With one room per house, completing a wall completes the house.
  bool advanceRoom() {
    return true;
  }

  /// Purchase an upgrade. Returns true if successful.
  bool purchaseUpgrade(UpgradeType type) {
    // Wider Roller is no longer a generic upgrade — it's now rollerLevel
    if (type == UpgradeType.widerRoller) return false;

    final def = UpgradeDefinition.getDefinition(type);
    final currentLevel = _progress.getUpgradeLevel(type);
    if (def.isMaxed(currentLevel)) return false;

    final cost = def.costForLevel(currentLevel);
    if (_progress.cash < cost) return false;

    _progress.cash -= cost;
    _progress.upgradeLevels[type] = currentLevel + 1;
    _saveLocally();
    notifyListeners();
    return true;
  }

  bool canAffordUpgrade(UpgradeType type) {
    if (type == UpgradeType.widerRoller) return false;
    final def = UpgradeDefinition.getDefinition(type);
    final currentLevel = _progress.getUpgradeLevel(type);
    if (def.isMaxed(currentLevel)) return false;
    return _progress.cash >= def.costForLevel(currentLevel);
  }

  /// Advance to next house after painting (free, just next wall of same level).
  /// The house type stays the same within a level — you paint the same house
  /// repeatedly until you upgrade.
  void nextHouseFree() {
    _progress.lastOnlineAt = DateTime.now();
    _saveLocally();
    notifyListeners();
  }

  /// Upgrade house level: costs cash, increases to next house in the cycle.
  bool upgradeHouse() {
    if (!_progress.canUpgradeHouseLevel) return false;
    final cost = _progress.houseUpgradeCost;
    if (_progress.cash < cost) return false;

    _progress.cash -= cost;
    _progress.houseLevel++;
    _progress.lastOnlineAt = DateTime.now();
    _saveLocally();
    notifyListeners();
    return true;
  }

  /// Upgrade roller size: costs cash, makes roller wider.
  bool upgradeRoller() {
    if (!_progress.canUpgradeRollerLevel) return false;
    final cost = _progress.rollerUpgradeCost;
    if (_progress.cash < cost) return false;

    _progress.cash -= cost;
    _progress.rollerLevel++;
    _saveLocally();
    notifyListeners();
    return true;
  }

  double get houseUpgradeCost => _progress.houseUpgradeCost;
  bool get canAffordHouseUpgrade =>
      _progress.cash >= _progress.houseUpgradeCost && _progress.canUpgradeHouseLevel;

  double get rollerUpgradeCost => _progress.rollerUpgradeCost;
  bool get canAffordRollerUpgrade =>
      _progress.cash >= _progress.rollerUpgradeCost && _progress.canUpgradeRollerLevel;

  /// Whether the coupling constraint blocks house upgrade.
  bool get houseLevelBlocked => !_progress.canUpgradeHouseLevel;

  /// Whether the coupling constraint blocks roller upgrade.
  bool get rollerLevelBlocked => !_progress.canUpgradeRollerLevel;

  /// Calculate and apply idle income from time away.
  double applyIdleIncome(Duration offlineDuration) {
    if (_progress.idleIncomePerSecond <= 0) return 0;

    // Cap at 8 hours
    final cappedSeconds = offlineDuration.inSeconds.clamp(0, 8 * 3600);
    final income = _progress.idleIncomePerSecond * cappedSeconds;

    if (income > 0) {
      _progress.cash += income;
      _progress.lastOnlineAt = DateTime.now();
      _saveLocally();
      notifyListeners();
    }
    return income;
  }

  /// Update last online time (call on app pause).
  void updateLastOnline() {
    _progress.lastOnlineAt = DateTime.now();
    _saveLocally();
  }

  /// Get the offline duration since last online.
  Duration getOfflineDuration() {
    return DateTime.now().difference(_progress.lastOnlineAt);
  }

  // ── Roller Skins ──

  bool ownsSkin(String id) => _progress.ownedSkins.contains(id);

  bool canAffordSkin(String id) {
    final def = rollerSkinDefs.where((s) => s.id == id).firstOrNull;
    if (def == null) return false;
    return _progress.cash >= def.price;
  }

  /// Purchase a roller skin. Returns true if successful.
  bool purchaseSkin(String skinId) {
    if (ownsSkin(skinId)) return false;
    final def = rollerSkinDefs.where((s) => s.id == skinId).firstOrNull;
    if (def == null) return false;
    if (_progress.cash < def.price) return false;

    _progress.cash -= def.price;
    _progress.ownedSkins.add(skinId);
    _progress.equippedSkin = skinId;
    _saveLocally();
    notifyListeners();
    return true;
  }

  /// Equip an already-owned skin.
  void equipSkin(String skinId) {
    if (!ownsSkin(skinId)) return;
    if (_progress.equippedSkin == skinId) return;
    _progress.equippedSkin = skinId;
    _saveLocally();
    notifyListeners();
  }

  /// Reset all progress (debug).
  Future<void> resetAll() async {
    _progress = PlayerProgress();
    _saveLocally();
    notifyListeners();
  }
}
