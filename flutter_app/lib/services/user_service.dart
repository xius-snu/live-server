import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class UserService extends ChangeNotifier {
  String? _userId;
  String? _username;
  String? _friendCode;
  String? _authToken;

  static const String _host = 'live-server-4c3n.onrender.com';
  String get _baseUrl => 'https://$_host';
  String get baseUrl => _baseUrl;
  String get host => _host;

  String? get userId => _userId;
  String? get username => _username;
  String? get friendCode => _friendCode;
  bool get hasUser => _userId != null && _username != null;

  /// Returns auth headers for authenticated API requests.
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<void> init() async {
    _userId = await _getStableDeviceId();

    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _friendCode = prefs.getString('friend_code');
    _authToken = prefs.getString('auth_token');

    if (_friendCode == null) {
      await _generateFriendCode();
    }

    if (_username == null && _userId != null) {
      await _fetchUsernameFromServer();
    }

    // Legacy account migration: if user exists but has no auth token,
    // re-register with existing username to obtain one from the server.
    if (_authToken == null && _username != null && _userId != null) {
      await _refreshAuthToken();
    }

    // Sync friend code to server on every launch
    if (_userId != null && _friendCode != null) {
      _syncFriendCode();
    }

    notifyListeners();
  }

  /// Push local friend code to the server.
  Future<void> _syncFriendCode() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/sync-friend-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': _userId, 'friendCode': _friendCode}),
      );
      debugPrint('Sync friend code response: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('Sync friend code error: $e');
    }
  }

  Future<void> _generateFriendCode() async {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    _friendCode = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('friend_code', _friendCode!);
  }

  Future<String> _getStableDeviceId() async {
    const storage = FlutterSecureStorage();
    String? uniqueId;

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        uniqueId = androidInfo.id;
      } else if (!kIsWeb && Platform.isIOS) {
        uniqueId = await storage.read(key: 'device_unique_id');
        if (uniqueId == null) {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          uniqueId = iosInfo.identifierForVendor ?? DateTime.now().toIso8601String();
          await storage.write(key: 'device_unique_id', value: uniqueId);
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        uniqueId = prefs.getString('device_unique_id');
        if (uniqueId == null) {
          uniqueId = DateTime.now().toIso8601String();
          await prefs.setString('device_unique_id', uniqueId);
        }
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      uniqueId = 'fallback-${DateTime.now().millisecondsSinceEpoch}';
    }

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

  /// Re-register with existing username to obtain an auth token for legacy accounts.
  Future<void> _refreshAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'username': _username,
          'friendCode': _friendCode,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
          debugPrint('Legacy auth token obtained');
        }
      }
    } catch (e) {
      debugPrint('Refresh auth token error: $e');
    }
  }

  /// Save the auth token returned by the server.
  Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<bool> setUsername(String name) async {
    try {
      if (_userId == null) await init();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/user'),
        headers: authHeaders,
        body: json.encode({
          'userId': _userId,
          'username': name,
          'friendCode': _friendCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _username = data['username'] ?? name;
        // Save token if server issued one (new user or migration)
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _username!);
        // Sync friend code now that user exists in DB
        if (_friendCode != null) {
          await _syncFriendCode();
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error setting username: $e');
      return false;
    }
  }

  String getWsUrl(String path) {
    return 'wss://$_host/ws/$path?userId=$_userId&username=$_username';
  }

  /// Look up a user by friend code. Returns {user_id, username, friend_code} or null.
  Future<Map<String, dynamic>?> lookupByFriendCode(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/by-code/${code.toUpperCase()}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Lookup by code error: $e');
      return null;
    }
  }

  /// Send a friend request. Returns response map with 'status' ('pending' or 'accepted') or 'error'.
  Future<Map<String, dynamic>?> sendFriendRequest(String friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/add'),
        headers: authHeaders,
        body: json.encode({'userId': _userId, 'friendId': friendId}),
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Send friend request error: $e');
      return null;
    }
  }

  /// Accept an incoming friend request.
  Future<bool> acceptFriendRequest(String requesterId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/accept'),
        headers: authHeaders,
        body: json.encode({'userId': _userId, 'requesterId': requesterId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Accept friend request error: $e');
      return false;
    }
  }

  /// Decline an incoming friend request.
  Future<bool> declineFriendRequest(String requesterId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/decline'),
        headers: authHeaders,
        body: json.encode({'userId': _userId, 'requesterId': requesterId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Decline friend request error: $e');
      return false;
    }
  }

  /// Cancel a pending friend request I sent.
  Future<bool> cancelFriendRequest(String friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/cancel'),
        headers: authHeaders,
        body: json.encode({'userId': _userId, 'friendId': friendId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Cancel friend request error: $e');
      return false;
    }
  }

  /// Remove a friend (unfriend).
  Future<bool> removeFriend(String friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/friends/remove'),
        headers: authHeaders,
        body: json.encode({'userId': _userId, 'friendId': friendId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Remove friend error: $e');
      return false;
    }
  }

  /// List friends, incoming requests, and outgoing requests.
  Future<Map<String, dynamic>> listFriends() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/friends/$_userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {'friends': [], 'incoming': [], 'outgoing': []};
    } catch (e) {
      debugPrint('List friends error: $e');
      return {'friends': [], 'incoming': [], 'outgoing': []};
    }
  }

  /// Get a user's public profile (for friend profile view).
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get profile error: $e');
      return null;
    }
  }
}
