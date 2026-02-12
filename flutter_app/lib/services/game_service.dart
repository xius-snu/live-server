import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_progress.dart';
import '../models/upgrade.dart';
import '../models/house.dart';

class GameService extends ChangeNotifier {
  PlayerProgress _progress = PlayerProgress();
  bool _initialized = false;

  PlayerProgress get progress => _progress;
  bool get initialized => _initialized;

  // Convenience getters
  double get cash => _progress.cash;
  int get stars => _progress.stars;
  int get prestigeLevel => _progress.prestigeLevel;
  HouseTier get currentHouse => _progress.currentHouse;
  int get currentRoom => _progress.currentRoom;
  int get maxStrokes => _progress.maxStrokes;
  double get rollerWidthPercent => _progress.rollerWidthPercent;
  double get rollerSpeedMultiplier => _progress.rollerSpeedMultiplier;
  bool get canPrestige => _progress.canPrestige;

  HouseDefinition get currentHouseDef => HouseDefinition.getDefinition(_progress.currentHouse);
  RoomDefinition get currentRoomDef => currentHouseDef.rooms[_progress.currentRoom];

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

  /// Complete a paint round. Returns the cash earned.
  double completePaintRound(double coverage) {
    final house = HouseDefinition.getDefinition(_progress.currentHouse);
    final baseCash = house.baseCashPerWall;

    // Coverage bonus
    int coverageBonus = 1;
    if (coverage >= 1.0) {
      coverageBonus = 5;
    } else if (coverage >= 0.95) {
      coverageBonus = 3;
    } else if (coverage >= 0.90) {
      coverageBonus = 2;
    }

    final payout = baseCash *
        _progress.starMultiplier *
        _progress.cashPerTapMultiplier *
        coverageBonus;

    _progress.cash += payout;
    _progress.totalCashEarned += payout;
    _progress.totalWallsPainted++;
    _progress.lastOnlineAt = DateTime.now();

    _saveLocally();
    notifyListeners();
    return payout;
  }

  /// Advance to the next room. Returns true if prestige is now available.
  bool advanceRoom() {
    final house = HouseDefinition.getDefinition(_progress.currentHouse);
    if (_progress.currentRoom < house.rooms.length - 1) {
      _progress.currentRoom++;
      _saveLocally();
      notifyListeners();
      return false;
    }
    // All rooms complete — prestige available
    return true;
  }

  /// Purchase an upgrade. Returns true if successful.
  bool purchaseUpgrade(UpgradeType type) {
    final def = UpgradeDefinition.getDefinition(type);
    final currentLevel = _progress.getUpgradeLevel(type);
    if (currentLevel >= def.maxLevel) return false;

    final cost = def.costForLevel(currentLevel);
    if (_progress.cash < cost) return false;

    _progress.cash -= cost;
    _progress.upgradeLevels[type] = currentLevel + 1;
    _saveLocally();
    notifyListeners();
    return true;
  }

  bool canAffordUpgrade(UpgradeType type) {
    final def = UpgradeDefinition.getDefinition(type);
    final currentLevel = _progress.getUpgradeLevel(type);
    if (currentLevel >= def.maxLevel) return false;
    return _progress.cash >= def.costForLevel(currentLevel);
  }

  /// Prestige: reset cash & upgrades, gain a star, advance house tier.
  void prestige() {
    final nextHouse = HouseDefinition.nextTier(_progress.currentHouse);

    _progress.cash = 0;
    _progress.stars++;
    _progress.prestigeLevel++;
    _progress.currentRoom = 0;
    _progress.upgradeLevels.clear();

    if (nextHouse != null) {
      _progress.currentHouse = nextHouse;
    }
    // If at max house tier, stay there but still gain stars

    _progress.lastOnlineAt = DateTime.now();
    _saveLocally();
    notifyListeners();
  }

  /// Calculate and apply idle income from time away.
  double applyIdleIncome(Duration offlineDuration) {
    if (_progress.idleIncomePerSecond <= 0) return 0;

    // Cap at 8 hours
    final cappedSeconds = offlineDuration.inSeconds.clamp(0, 8 * 3600);
    final income = _progress.idleIncomePerSecond *
        cappedSeconds *
        _progress.starMultiplier;

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

  /// Reset all progress (debug).
  Future<void> resetAll() async {
    _progress = PlayerProgress();
    _saveLocally();
    notifyListeners();
  }
}
