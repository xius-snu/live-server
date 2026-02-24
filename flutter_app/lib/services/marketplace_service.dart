import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/marketplace_item.dart';

/// Default shop items that can be bought with cash (not gems).
/// These rotate or are always available — no player listing needed.
class ShopItem {
  final String itemTypeId;
  final String name;
  final String icon;
  final double cashPrice;
  final String description;
  final int? stockLimit; // null = unlimited

  const ShopItem({
    required this.itemTypeId,
    required this.name,
    required this.icon,
    required this.cashPrice,
    required this.description,
    this.stockLimit,
  });
}

class MarketplaceService extends ChangeNotifier {
  String baseUrl;
  String? Function() userIdGetter;

  List<SerializedItem> _inventory = [];
  List<MarketplaceListing> _communityListings = [];
  Map<String, double> _indexPrices = {};
  bool _loading = false;
  String? _error;

  MarketplaceService({required this.baseUrl, required this.userIdGetter});

  List<SerializedItem> get inventory => _inventory;
  List<SerializedItem> get unlistedInventory =>
      _inventory.where((i) => !i.isListed).toList();
  List<MarketplaceListing> get communityListings => _communityListings;
  Map<String, double> get indexPrices => _indexPrices;
  bool get loading => _loading;
  String? get error => _error;

  /// Default shop: always-available items bought with cash.
  static const List<ShopItem> defaultShop = [
    ShopItem(
      itemTypeId: 'basic_paint',
      name: 'Basic Paint Can',
      icon: '\u{1F3A8}',
      cashPrice: 25,
      description: 'Standard white paint. A painter\'s staple.',
    ),
    ShopItem(
      itemTypeId: 'speed_boost',
      name: 'Speed Boost (1hr)',
      icon: '\u{26A1}',
      cashPrice: 100,
      description: '2x cash earnings for 1 hour.',
      stockLimit: 3,
    ),
    ShopItem(
      itemTypeId: 'premium_paint',
      name: 'Premium Paint Can',
      icon: '\u{2728}',
      cashPrice: 200,
      description: 'High-quality premium paint with a smooth finish.',
    ),
    ShopItem(
      itemTypeId: 'gold_roller',
      name: 'Gold Roller Skin',
      icon: '\u{1F31F}',
      cashPrice: 500,
      description: 'A shiny golden paint roller.',
      stockLimit: 1,
    ),
  ];

  String? get _userId => userIdGetter();

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();

    await Future.wait([
      fetchInventory(),
      fetchCommunityListings(),
      fetchIndexPrices(),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> fetchInventory() async {
    if (_userId == null) return;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/inventory/$_userId'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = (data['items'] as List?) ?? [];
        _inventory = items.map((j) => SerializedItem.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Inventory fetch error: $e');
    }
  }

  Future<void> fetchCommunityListings() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/marketplace/listings'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final listings = (data['listings'] as List?) ?? [];
        _communityListings =
            listings.map((j) => MarketplaceListing.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Community listings fetch error: $e');
    }
  }

  Future<void> fetchIndexPrices() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/marketplace/index-prices'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final prices = data['prices'] as Map<String, dynamic>? ?? {};
        _indexPrices = {};
        for (final entry in prices.entries) {
          final info = entry.value as Map<String, dynamic>;
          _indexPrices[entry.key] = (info['avgPrice'] as num?)?.toDouble() ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Index prices fetch error: $e');
    }
  }

  /// Buy from community auction house. Returns error string or null on success.
  Future<String?> buyListing(String listingId) async {
    if (_userId == null) return 'Not logged in';
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/marketplace/buy'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'listingId': listingId,
        }),
      );
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        await loadAll();
        return null;
      }
      return data['error'] ?? 'Purchase failed';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// List an item on the community market. Returns error string or null.
  Future<String?> listItem(String instanceId, int priceGems,
      double feePercent) async {
    if (_userId == null) return 'Not logged in';
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/marketplace/list'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'instanceId': instanceId,
          'priceStars': priceGems,
          'feePercent': feePercent,
        }),
      );
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        await loadAll();
        return null;
      }
      return data['error'] ?? 'Listing failed';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Cancel a listing. Returns error string or null.
  Future<String?> cancelListing(String listingId) async {
    if (_userId == null) return 'Not logged in';
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/marketplace/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'listingId': listingId,
        }),
      );
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        await loadAll();
        return null;
      }
      return data['error'] ?? 'Cancel failed';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Get my active listings from community listings.
  List<MarketplaceListing> get myListings {
    final uid = _userId;
    if (uid == null) return [];
    return _communityListings.where((l) => l.sellerId == uid).toList();
  }
}
