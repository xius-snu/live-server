import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Represents an inventory item with tracking for trades
class InventoryItem {
  final String id;
  final String shapeType;
  final String rarity;
  final DateTime acquiredAt;
  String? pendingTradeId; // Locks item during trade

  InventoryItem({
    required this.id,
    required this.shapeType,
    required this.rarity,
    required this.acquiredAt,
    this.pendingTradeId,
  });

  bool get isLocked => pendingTradeId != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'shape_type': shapeType,
    'rarity': rarity,
    'acquired_at': acquiredAt.toIso8601String(),
    'pending_trade_id': pendingTradeId,
  };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] ?? json['inventory_id'] ?? '',
    shapeType: json['shape_type'] ?? json['shapeType'] ?? '',
    rarity: json['rarity'] ?? 'Common',
    acquiredAt: json['acquired_at'] != null
        ? DateTime.parse(json['acquired_at'])
        : DateTime.now(),
    pendingTradeId: json['pending_trade_id'],
  );
}

class UserService extends ChangeNotifier {
  String? _userId;
  String? _username;
  String? _profileShape; // The shape set as profile picture
  Map<String, int> _inventory = {}; // shape -> quantity (legacy aggregated)
  List<InventoryItem> _inventoryItems = []; // Full inventory with individual items

  // Progression fields
  int _affinityTier = 1; // 1-4, assigned on account creation
  String? _friendCode; // Unique shareable code
  int _streakCount = 0; // Current consecutive wins
  int _totalSuccesses = 0; // Lifetime successful draws
  Set<String> _collectedShapes = {}; // Unique shapes collected (for progression)

  // Render hosted server
  static const String _host = 'live-server-4c3n.onrender.com';
  String get _baseUrl => 'https://$_host';

  String get baseUrl => _baseUrl;

  String? get userId => _userId;
  String? get username => _username;
  String? get profileShape => _profileShape;
  Map<String, int> get inventory => Map.unmodifiable(_inventory);
  List<InventoryItem> get inventoryItems => List.unmodifiable(_inventoryItems);

  // Progression getters
  int get affinityTier => _affinityTier;
  String? get friendCode => _friendCode;
  int get streakCount => _streakCount;
  int get totalSuccesses => _totalSuccesses;
  Set<String> get collectedShapes => Set.unmodifiable(_collectedShapes);

  bool get hasUser => _userId != null && _username != null;

  Future<void> init() async {
    _userId = await _getStableDeviceId();

    // Check if we have a username locally first
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _profileShape = prefs.getString('profile_shape');

    // Load inventory from local storage (legacy aggregated)
    final inventoryJson = prefs.getString('inventory');
    if (inventoryJson != null) {
      final Map<String, dynamic> decoded = json.decode(inventoryJson);
      _inventory = decoded.map((k, v) => MapEntry(k, v as int));
    }

    // Load individual inventory items
    final itemsJson = prefs.getString('inventory_items');
    if (itemsJson != null) {
      final List<dynamic> decoded = json.decode(itemsJson);
      _inventoryItems = decoded.map((e) => InventoryItem.fromJson(e)).toList();
    }

    // Load progression data
    _affinityTier = prefs.getInt('affinity_tier') ?? 0;
    _friendCode = prefs.getString('friend_code');
    _streakCount = prefs.getInt('streak_count') ?? 0;
    _totalSuccesses = prefs.getInt('total_successes') ?? 0;

    // Load collected shapes
    final collectedJson = prefs.getString('collected_shapes');
    if (collectedJson != null) {
      _collectedShapes = Set<String>.from(json.decode(collectedJson));
    }

    // If no affinity assigned yet, assign one (new user)
    if (_affinityTier == 0) {
      await _assignAffinity();
    }

    // If no friend code yet, generate one
    if (_friendCode == null) {
      await _generateFriendCode();
    }

    // If no local username, check server
    if (_username == null && _userId != null) {
      await _fetchUsernameFromServer();
    }

    notifyListeners();
  }

  /// Assign random affinity tier (1-4) for new users
  Future<void> _assignAffinity() async {
    final random = Random();
    _affinityTier = random.nextInt(4) + 1; // 1, 2, 3, or 4
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('affinity_tier', _affinityTier);
  }

  /// Generate unique friend code
  Future<void> _generateFriendCode() async {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    _friendCode = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('friend_code', _friendCode!);

    // Sync to server
    if (_userId != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/api/user/friend-code'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': _userId,
            'friendCode': _friendCode,
          }),
        );
      } catch (e) {
        debugPrint('Friend code sync failed: $e');
      }
    }
  }

  Future<String> _getStableDeviceId() async {
    const storage = FlutterSecureStorage();
    String? uniqueId;

    try {
      if (Platform.isAndroid) {
        // Android: Use android_id
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        uniqueId = androidInfo.id; // stable across reinstalls
      } else if (Platform.isIOS) {
        // iOS: Use Keychain
        uniqueId = await storage.read(key: 'device_unique_id');
        if (uniqueId == null) {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          uniqueId = iosInfo.identifierForVendor ?? DateTime.now().toIso8601String();
          await storage.write(key: 'device_unique_id', value: uniqueId);
        }
      } else {
        // Fallback for Windows/Web
        final prefs = await SharedPreferences.getInstance();
        uniqueId = prefs.getString('device_unique_id');
        if (uniqueId == null) {
          uniqueId = DateTime.now().toIso8601String(); // Not stable across reinstall on Windows yet
          await prefs.setString('device_unique_id', uniqueId);
        }
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      uniqueId = 'fallback-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Hash it effectively to verify clean format
    final bytes = utf8.encode(uniqueId!);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32); 
  }

  Future<void> _fetchUsernameFromServer() async {
    if (_userId == null) return;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/user/$_userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['username'] != null) {
          _username = data['username'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', _username!);
        }
      }
    } catch (e) {
      debugPrint('Fetch user error: $e');
    }
  }

  Future<bool> setUsername(String name) async {
    try {
      if (_userId == null) await init();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'username': name,
        }),
      );

      if (response.statusCode == 200) {
        _username = name;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', name);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error setting username: $e');
      return false;
    }
  }

  Future<bool> addInventoryItem(String shapeType, String rarity) async {
    // Create individual inventory item
    final itemId = '${DateTime.now().millisecondsSinceEpoch}_${_inventoryItems.length}';
    final item = InventoryItem(
      id: itemId,
      shapeType: shapeType,
      rarity: rarity,
      acquiredAt: DateTime.now(),
    );
    _inventoryItems.add(item);

    // Update aggregated count (legacy)
    _inventory[shapeType] = (_inventory[shapeType] ?? 0) + 1;

    // Track collected shapes for progression
    _collectedShapes.add(shapeType);

    await _saveInventoryLocally();
    await _saveProgressionLocally();
    notifyListeners();

    // Try to sync with server (best effort)
    if (_userId != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/api/inventory/add'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': _userId,
            'shapeType': shapeType,
            'rarity': rarity,
          }),
        );
      } catch (e) {
        debugPrint('Server sync failed (offline mode): $e');
      }
    }
    return true;
  }

  Future<void> _saveInventoryLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventory', json.encode(_inventory));
    await prefs.setString(
      'inventory_items',
      json.encode(_inventoryItems.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveProgressionLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak_count', _streakCount);
    await prefs.setInt('total_successes', _totalSuccesses);
    await prefs.setString('collected_shapes', json.encode(_collectedShapes.toList()));
  }

  // Streak management
  void incrementStreak() {
    _streakCount++;
    _totalSuccesses++;
    _saveProgressionLocally();
    notifyListeners();
  }

  void resetStreak() {
    _streakCount = 0;
    _saveProgressionLocally();
    notifyListeners();
  }

  void preserveStreak() {
    // Called on near-miss (60-69%) - don't reset streak
    notifyListeners();
  }

  // Get unlockable inventory items (not locked in pending trade)
  List<InventoryItem> getAvailableItems() {
    return _inventoryItems.where((item) => !item.isLocked).toList();
  }

  // Get items by shape type
  List<InventoryItem> getItemsByShape(String shapeType) {
    return _inventoryItems.where((item) => item.shapeType == shapeType).toList();
  }

  // Lock items for trade
  Future<void> lockItemsForTrade(List<String> itemIds, String tradeId) async {
    for (final item in _inventoryItems) {
      if (itemIds.contains(item.id)) {
        item.pendingTradeId = tradeId;
      }
    }
    await _saveInventoryLocally();
    notifyListeners();
  }

  // Unlock items (trade cancelled/declined/expired)
  Future<void> unlockItems(String tradeId) async {
    for (final item in _inventoryItems) {
      if (item.pendingTradeId == tradeId) {
        item.pendingTradeId = null;
      }
    }
    await _saveInventoryLocally();
    notifyListeners();
  }

  // Remove items from inventory (after trade accepted)
  Future<void> removeItems(List<String> itemIds) async {
    _inventoryItems.removeWhere((item) => itemIds.contains(item.id));

    // Recalculate aggregated inventory
    _inventory.clear();
    for (final item in _inventoryItems) {
      _inventory[item.shapeType] = (_inventory[item.shapeType] ?? 0) + 1;
    }

    await _saveInventoryLocally();
    notifyListeners();
  }

  // Add items from trade
  Future<void> addItemsFromTrade(List<InventoryItem> items) async {
    for (final item in items) {
      item.pendingTradeId = null; // Clear lock
      _inventoryItems.add(item);
      _inventory[item.shapeType] = (_inventory[item.shapeType] ?? 0) + 1;
      _collectedShapes.add(item.shapeType);
    }
    await _saveInventoryLocally();
    await _saveProgressionLocally();
    notifyListeners();
  }

  // Clear all inventory (debug)
  Future<void> clearInventory() async {
    _inventory.clear();
    _inventoryItems.clear();
    _collectedShapes.clear();
    _streakCount = 0;
    _totalSuccesses = 0;

    await _saveInventoryLocally();
    await _saveProgressionLocally();

    // Clear on server
    if (_userId != null) {
      try {
        await http.delete(
          Uri.parse('$_baseUrl/api/inventory/clear/$_userId'),
        );
      } catch (e) {
        debugPrint('Server clear failed: $e');
      }
    }

    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getInventory() async {
    // Return aggregated inventory from local storage
    return _inventory.entries
        .map((e) => {'shape_type': e.key, 'quantity': e.value})
        .toList();
  }

  // Set a shape as the profile picture
  Future<void> setProfileShape(String? shape) async {
    _profileShape = shape;
    final prefs = await SharedPreferences.getInstance();
    if (shape != null) {
      await prefs.setString('profile_shape', shape);
    } else {
      await prefs.remove('profile_shape');
    }
    notifyListeners();
  }

  // Check if user has unlocked a specific shape
  bool hasShape(String shape) {
    return (_inventory[shape] ?? 0) > 0;
  }

  // Helper to get formatted URL for websockets
  String getWsUrl(String lobbyId) {
    return 'wss://$_host/ws/$lobbyId?role=viewer&userId=$_userId&username=$_username';
  }
}
