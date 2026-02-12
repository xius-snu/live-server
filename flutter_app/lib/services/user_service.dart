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

  static const String _host = 'live-server-4c3n.onrender.com';
  String get _baseUrl => 'https://$_host';
  String get baseUrl => _baseUrl;
  String get host => _host;

  String? get userId => _userId;
  String? get username => _username;
  String? get friendCode => _friendCode;
  bool get hasUser => _userId != null && _username != null;

  Future<void> init() async {
    _userId = await _getStableDeviceId();

    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _friendCode = prefs.getString('friend_code');

    if (_friendCode == null) {
      await _generateFriendCode();
    }

    if (_username == null && _userId != null) {
      await _fetchUsernameFromServer();
    }

    notifyListeners();
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

  String getWsUrl(String path) {
    return 'wss://$_host/ws/$path?userId=$_userId&username=$_username';
  }
}
