import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart';

/// Represents an item in a trade
class TradeItem {
  final String inventoryId;
  final String shapeType;
  final String rarity;

  TradeItem({
    required this.inventoryId,
    required this.shapeType,
    required this.rarity,
  });

  Map<String, dynamic> toJson() => {
    'inventory_id': inventoryId,
    'shape_type': shapeType,
    'rarity': rarity,
  };

  factory TradeItem.fromJson(Map<String, dynamic> json) => TradeItem(
    inventoryId: json['inventory_id'] ?? json['inventoryId'] ?? '',
    shapeType: json['shape_type'] ?? json['shapeType'] ?? '',
    rarity: json['rarity'] ?? 'Common',
  );
}

/// Trade request status
enum TradeStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired,
}

/// Represents a trade request
class TradeRequest {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? fromProfileShape;
  final String toUserId;
  final String toUsername;
  final String? toProfileShape;
  final List<TradeItem> offerItems;
  final List<TradeItem> requestItems;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  TradeRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.fromProfileShape,
    required this.toUserId,
    required this.toUsername,
    this.toProfileShape,
    required this.offerItems,
    required this.requestItems,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isPending => status == TradeStatus.pending;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'id': id,
    'from_user_id': fromUserId,
    'from_username': fromUsername,
    'from_profile_shape': fromProfileShape,
    'to_user_id': toUserId,
    'to_username': toUsername,
    'to_profile_shape': toProfileShape,
    'offer_items': offerItems.map((i) => i.toJson()).toList(),
    'request_items': requestItems.map((i) => i.toJson()).toList(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
  };

  factory TradeRequest.fromJson(Map<String, dynamic> json) {
    TradeStatus parseStatus(String? s) {
      switch (s) {
        case 'accepted': return TradeStatus.accepted;
        case 'declined': return TradeStatus.declined;
        case 'cancelled': return TradeStatus.cancelled;
        case 'expired': return TradeStatus.expired;
        default: return TradeStatus.pending;
      }
    }

    return TradeRequest(
      id: json['id'] ?? '',
      fromUserId: json['from_user_id'] ?? json['fromUserId'] ?? '',
      fromUsername: json['from_username'] ?? json['fromUsername'] ?? 'Unknown',
      fromProfileShape: json['from_profile_shape'] ?? json['fromProfileShape'],
      toUserId: json['to_user_id'] ?? json['toUserId'] ?? '',
      toUsername: json['to_username'] ?? json['toUsername'] ?? 'Unknown',
      toProfileShape: json['to_profile_shape'] ?? json['toProfileShape'],
      offerItems: (json['offer_items'] ?? json['offerItems'] ?? [])
          .map<TradeItem>((i) => TradeItem.fromJson(i))
          .toList(),
      requestItems: (json['request_items'] ?? json['requestItems'] ?? [])
          .map<TradeItem>((i) => TradeItem.fromJson(i))
          .toList(),
      status: parseStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(days: 7)),
    );
  }
}

class TradeService extends ChangeNotifier {
  final String _baseUrl;
  final String _userId;
  final UserService _userService;

  List<TradeRequest> _incomingTrades = [];
  List<TradeRequest> _outgoingTrades = [];
  bool _isLoading = false;
  String? _error;

  TradeService({
    required String baseUrl,
    required String userId,
    required UserService userService,
  })  : _baseUrl = baseUrl,
        _userId = userId,
        _userService = userService;

  List<TradeRequest> get incomingTrades => List.unmodifiable(_incomingTrades);
  List<TradeRequest> get outgoingTrades => List.unmodifiable(_outgoingTrades);
  List<TradeRequest> get pendingIncoming =>
      _incomingTrades.where((t) => t.isPending && !t.isExpired).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all trade requests (incoming and outgoing)
  Future<void> loadTrades() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/trades/$_userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _incomingTrades = (data['incoming'] as List? ?? [])
            .map((t) => TradeRequest.fromJson(t))
            .toList();

        _outgoingTrades = (data['outgoing'] as List? ?? [])
            .map((t) => TradeRequest.fromJson(t))
            .toList();
      } else {
        _error = 'Failed to load trades';
      }
    } catch (e) {
      debugPrint('Load trades error: $e');
      _error = 'Network error';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new trade request
  /// Returns trade ID on success, null on failure
  Future<String?> createTradeRequest({
    required String toUserId,
    required List<InventoryItem> offerItems,
    required List<TradeItem> requestItems,
  }) async {
    if (offerItems.isEmpty || requestItems.isEmpty) {
      _error = 'Trade must include items from both sides';
      notifyListeners();
      return null;
    }

    if (offerItems.length > 3 || requestItems.length > 3) {
      _error = 'Maximum 3 items per side';
      notifyListeners();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trades/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fromUserId': _userId,
          'toUserId': toUserId,
          'offerItems': offerItems.map((i) => {
            'inventory_id': i.id,
            'shape_type': i.shapeType,
            'rarity': i.rarity,
          }).toList(),
          'requestItems': requestItems.map((i) => i.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tradeId = data['tradeId'] as String;

        // Lock offered items locally
        await _userService.lockItemsForTrade(
          offerItems.map((i) => i.id).toList(),
          tradeId,
        );

        await loadTrades();
        return tradeId;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to create trade';
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Create trade error: $e');
      _error = 'Network error';
      notifyListeners();
      return null;
    }
  }

  /// Accept a trade request (atomic swap on server)
  Future<bool> acceptTrade(String tradeId) async {
    final trade = _incomingTrades.firstWhere(
      (t) => t.id == tradeId,
      orElse: () => throw Exception('Trade not found'),
    );

    if (trade.isExpired) {
      _error = 'Trade has expired';
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trades/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'tradeId': tradeId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update local inventory
        // Remove items I'm giving away
        await _userService.removeItems(
          trade.requestItems.map((i) => i.inventoryId).toList(),
        );

        // Add items I'm receiving
        final receivedItems = (data['receivedItems'] as List?)?.map((i) =>
          InventoryItem.fromJson(i)
        ).toList() ?? [];
        await _userService.addItemsFromTrade(receivedItems);

        await loadTrades();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to accept trade';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Accept trade error: $e');
      _error = 'Network error';
      notifyListeners();
      return false;
    }
  }

  /// Decline a trade request
  Future<bool> declineTrade(String tradeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trades/decline'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'tradeId': tradeId,
        }),
      );

      if (response.statusCode == 200) {
        _incomingTrades.removeWhere((t) => t.id == tradeId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Decline trade error: $e');
      return false;
    }
  }

  /// Cancel an outgoing trade request
  Future<bool> cancelTrade(String tradeId) async {
    final trade = _outgoingTrades.firstWhere(
      (t) => t.id == tradeId,
      orElse: () => throw Exception('Trade not found'),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trades/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'tradeId': tradeId,
        }),
      );

      if (response.statusCode == 200) {
        // Unlock my items locally
        await _userService.unlockItems(tradeId);

        _outgoingTrades.removeWhere((t) => t.id == tradeId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Cancel trade error: $e');
      return false;
    }
  }

  /// Check for expired trades and clean up
  Future<void> cleanupExpiredTrades() async {
    for (final trade in _outgoingTrades) {
      if (trade.isExpired && trade.isPending) {
        await _userService.unlockItems(trade.id);
      }
    }
    await loadTrades();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
