import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/game_config.dart';
import '../models/player_progress.dart';
import '../models/roller_inventory_item.dart';
import '../models/upgrade.dart';
import '../models/house.dart';

/// Definition for a purchasable roller skin.
class RollerSkinDef {
  final String id;
  final String name;
  final String asset; // filename in assets/images/rollers/
  final double price; // coin cost

  const RollerSkinDef({
    required this.id,
    required this.name,
    required this.asset,
    required this.price,
  });
}

class GameService extends ChangeNotifier {
  PlayerProgress _progress = PlayerProgress();
  bool _initialized = false;
  final Random _rng = Random();

  /// The house level used for the current wall's visual appearance.
  /// Randomized each wall from a weighted pool of recently unlocked tiers.
  int _visualHouseLevel = 1;

  PlayerProgress get progress => _progress;
  bool get initialized => _initialized;

  /// All roller skins in order (least -> most expensive).
  static const List<RollerSkinDef> rollerSkinDefs = [
    RollerSkinDef(id: 'default', name: 'Default', asset: 'default.png', price: kSkinPriceDefault),
    RollerSkinDef(id: 'pudding', name: 'Pudding', asset: 'pudding.png', price: kSkinPricePudding),
    RollerSkinDef(id: 'pancake', name: 'Pancake', asset: 'pancake.png', price: kSkinPricePancake),
    RollerSkinDef(id: 'bunny', name: 'Bunny', asset: 'bunny.png', price: kSkinPriceBunny),
    RollerSkinDef(id: 'kitty', name: 'Kitty', asset: 'kitty.png', price: kSkinPriceKitty),
    RollerSkinDef(id: 'money', name: 'Money', asset: 'money.png', price: kSkinPriceMoney),
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
  String get equippedColorId => _progress.equippedColorId;
  List<RollerInventoryItem> get rollerInventory => _progress.rollerInventory;

  Color get equippedPaintColor {
    final colorDef = getPaintColorById(_progress.equippedColorId);
    if (colorDef != null) return Color(colorDef.hex);
    return const Color(kDefaultRollerPaintColor);
  }

  HouseDefinition get currentHouseDef => _progress.currentHouseDef;
  RoomDefinition get currentRoomDef => currentHouseDef.room;

  /// Visual house level for the current wall (randomized each round).
  int get visualHouseLevel => _visualHouseLevel;
  HouseDefinition get visualHouseDef => HouseDefinition.getForHouseLevel(_visualHouseLevel);
  int get visualCycleLevel => HouseDefinition.cycleLevelFor(_visualHouseLevel);

  Future<void> init() async {
    await _loadLocally();
    _rollVisualHouseLevel();
    _initialized = true;
    notifyListeners();
  }

  /// Roll a new random visual house level from the weighted tier pool.
  void _rollVisualHouseLevel() {
    _visualHouseLevel = HouseDefinition.randomWeightedHouseLevel(
      _progress.houseLevel, _rng,
    );
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

  /// Sync progress to the server so friends can see real stats.
  Future<void> syncProgressToServer(String baseUrl, String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/progress/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'cash': _progress.cash,
          'stars': _progress.gems,
          'prestigeLevel': _progress.houseLevel,
          'currentHouse': _progress.currentHouse.name,
          'currentRoom': 0,
          'upgrades': {for (final e in _progress.upgradeLevels.entries) e.key.name: e.value},
          'totalWallsPainted': _progress.totalWallsPainted,
          'totalCashEarned': _progress.totalCashEarned,
        }),
      );
    } catch (e) {
      debugPrint('Sync progress to server error: $e');
    }
  }

  /// Coverage bonus multiplier for high coverage rounds.
  static double coverageBonus(double coverage) {
    if (coverage >= 1.0) return kCoverageBonusPerfect;
    if (coverage >= 0.95) return kCoverageBonusGreat;
    if (coverage >= 0.90) return kCoverageBonusNice;
    return 1.0;
  }

  /// Streak cash bonus multiplier. 5% per streak level, uncapped.
  static double streakBonusMultiplier(int streak) {
    return kStreakBonusPerLevel * streak;
  }

  /// Complete a paint round. Returns (basePayout, streakBonus).
  (double payout, double streakBonus) completePaintRound(double coverage) {
    final baseCash = _progress.baseCashPerWall;

    final coverageFactor = pow(coverage.clamp(0.0, 1.0), kCoverageRewardExponent).toDouble();
    final bonus = coverageBonus(coverage.clamp(0.0, 1.0));

    final basePayout = baseCash *
        coverageFactor *
        bonus *
        _progress.cashPerTapMultiplier;

    // Tiered streak system:
    // - 2x+ (GREAT/PERFECT): advances up to streak max
    // - 1.5x (NICE): advances up to streak nice cap, drops to cap if above
    // - No bonus: resets to 0
    final oldStreak = _progress.streak;
    if (bonus >= kCoverageBonusGreat) {
      _progress.streak = (oldStreak + 1).clamp(0, kStreakMaxLevel);
    } else if (bonus >= kCoverageBonusNice) {
      if (oldStreak < kStreakNiceCap) {
        _progress.streak = oldStreak + 1;
      } else {
        _progress.streak = kStreakNiceCap;
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
    if (coverage >= 1.0) {
      _progress.hasPerfectedCurrentHouse = true;
    }
    _progress.lastOnlineAt = DateTime.now();

    _saveLocally();
    notifyListeners();
    return (basePayout, streakCashBonus);
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

  /// Advance to next wall after painting. Rolls a new random house type
  /// from the weighted pool of recently unlocked tiers.
  void nextHouseFree() {
    _rollVisualHouseLevel();
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
    _progress.hasPerfectedCurrentHouse = false;
    _rollVisualHouseLevel();
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

    final cappedSeconds = offlineDuration.inSeconds.clamp(0, kIdleIncomeCapSeconds);
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

  // ── Roller Purchase & Equip ──

  bool canAffordRollerPurchase(String rollerId) {
    final def = rollerSkinDefs.where((s) => s.id == rollerId).firstOrNull;
    if (def == null) return false;
    return _progress.cash >= def.price;
  }

  /// Purchase a roller, rolling a random color. Returns the item or null.
  RollerInventoryItem? purchaseRoller(String rollerId) {
    final def = rollerSkinDefs.where((s) => s.id == rollerId).firstOrNull;
    if (def == null) return null;
    if (_progress.cash < def.price) return null;

    _progress.cash -= def.price;

    final color = rollRandomPaintColor(_rng);

    // Stack if same roller+color exists
    final existing = _progress.rollerInventory.where(
      (item) => item.rollerId == rollerId && item.colorId == color.id,
    ).firstOrNull;

    RollerInventoryItem resultItem;
    if (existing != null) {
      existing.count++;
      resultItem = existing;
    } else {
      resultItem = RollerInventoryItem(
        rollerId: rollerId,
        colorId: color.id,
        colorTier: color.tier,
        colorHex: color.hex,
      );
      _progress.rollerInventory.add(resultItem);
    }

    _saveLocally();
    notifyListeners();
    return resultItem;
  }

  /// Equip a specific roller+color from inventory.
  void equipRollerItem(String rollerId, String colorId) {
    final exists = _progress.rollerInventory.any(
      (item) => item.rollerId == rollerId && item.colorId == colorId && item.count > 0,
    );
    if (!exists) return;

    _progress.equippedSkin = rollerId;
    _progress.equippedColorId = colorId;
    _saveLocally();
    notifyListeners();
  }

  /// Remove one copy of a roller+color from inventory. Returns true if successful.
  bool removeRollerItem(String rollerId, String colorId) {
    final item = _progress.rollerInventory.where(
      (i) => i.rollerId == rollerId && i.colorId == colorId && i.count > 0,
    ).firstOrNull;
    if (item == null) return false;

    item.count--;
    if (item.count <= 0) {
      _progress.rollerInventory.remove(item);
    }
    _saveLocally();
    notifyListeners();
    return true;
  }

  /// Add debug coins without affecting leaderboard stats.
  void addDebugCoins(double amount) {
    _progress.cash += amount;
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
