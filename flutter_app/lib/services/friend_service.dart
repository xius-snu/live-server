import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a friend relationship
class Friend {
  final String userId;
  final String username;
  final String? profileShape;
  final String friendCode;
  final String status; // 'pending' | 'accepted'
  final DateTime createdAt;
  final bool isOnline;

  Friend({
    required this.userId,
    required this.username,
    this.profileShape,
    required this.friendCode,
    required this.status,
    required this.createdAt,
    this.isOnline = false,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'profile_shape': profileShape,
    'friend_code': friendCode,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'is_online': isOnline,
  };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    userId: json['user_id'] ?? json['userId'] ?? '',
    username: json['username'] ?? 'Unknown',
    profileShape: json['profile_shape'] ?? json['profileShape'],
    friendCode: json['friend_code'] ?? json['friendCode'] ?? '',
    status: json['status'] ?? 'pending',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
    isOnline: json['is_online'] ?? json['isOnline'] ?? false,
  );
}

/// Represents a friend request
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? fromProfileShape;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.fromProfileShape,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
    id: json['id'] ?? '',
    fromUserId: json['from_user_id'] ?? json['fromUserId'] ?? '',
    fromUsername: json['from_username'] ?? json['fromUsername'] ?? 'Unknown',
    fromProfileShape: json['from_profile_shape'] ?? json['fromProfileShape'],
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
  );
}

class FriendService extends ChangeNotifier {
  final String _baseUrl;
  final String _userId;

  List<Friend> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  bool _isLoading = false;
  String? _error;

  FriendService({required String baseUrl, required String userId})
      : _baseUrl = baseUrl,
        _userId = userId;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<Friend> get acceptedFriends => _friends.where((f) => f.isAccepted).toList();
  List<FriendRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load friends list from server
  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/friends/$_userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _friends = (data['friends'] as List)
            .map((f) => Friend.fromJson(f))
            .toList();
      } else {
        _error = 'Failed to load friends';
      }
    } catch (e) {
      debugPrint('Load friends error: $e');
      _error = 'Network error';
      // Load from cache
      await _loadFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load pending friend requests
  Future<void> loadPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/friends/requests/$_userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _pendingRequests = (data['requests'] as List)
            .map((r) => FriendRequest.fromJson(r))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load friend requests error: $e');
    }
  }

  /// Send friend request by username or friend code
  Future<bool> sendFriendRequest(String usernameOrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fromUserId': _userId,
          'targetIdentifier': usernameOrCode,
        }),
      );

      if (response.statusCode == 200) {
        // Reload friends to get updated list
        await loadFriends();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to send request';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Send friend request error: $e');
      _error = 'Network error';
      notifyListeners();
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'requestId': requestId,
        }),
      );

      if (response.statusCode == 200) {
        _pendingRequests.removeWhere((r) => r.id == requestId);
        await loadFriends();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Accept friend request error: $e');
      return false;
    }
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/decline'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'requestId': requestId,
        }),
      );

      if (response.statusCode == 200) {
        _pendingRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Decline friend request error: $e');
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String friendUserId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/friends/remove'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'friendUserId': friendUserId,
        }),
      );

      if (response.statusCode == 200) {
        _friends.removeWhere((f) => f.userId == friendUserId);
        await _saveToCache();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Remove friend error: $e');
      return false;
    }
  }

  /// Get friend's public inventory for trading
  Future<List<Map<String, dynamic>>> getFriendInventory(String friendUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/inventory/public/$friendUserId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['inventory'] ?? []);
      }
    } catch (e) {
      debugPrint('Get friend inventory error: $e');
    }
    return [];
  }

  /// Lookup user by friend code
  Future<Map<String, dynamic>?> lookupByFriendCode(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/by-code/$code'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Lookup by friend code error: $e');
    }
    return null;
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_friends_$_userId');
      if (cached != null) {
        final List<dynamic> decoded = json.decode(cached);
        _friends = decoded.map((f) => Friend.fromJson(f)).toList();
      }
    } catch (e) {
      debugPrint('Load from cache error: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_friends_$_userId',
        json.encode(_friends.map((f) => f.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Save to cache error: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
