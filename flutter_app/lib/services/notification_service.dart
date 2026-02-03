import 'package:flutter/foundation.dart';

/// Notification types for the app
enum NotificationType {
  friendRequest,
  friendAccepted,
  tradeRequest,
  tradeAccepted,
  tradeDeclined,
  tradeCancelled,
  tradeExpired,
}

/// Represents an in-app notification
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? s) {
      switch (s) {
        case 'friend_request': return NotificationType.friendRequest;
        case 'friend_accepted': return NotificationType.friendAccepted;
        case 'trade_request': return NotificationType.tradeRequest;
        case 'trade_accepted': return NotificationType.tradeAccepted;
        case 'trade_declined': return NotificationType.tradeDeclined;
        case 'trade_cancelled': return NotificationType.tradeCancelled;
        case 'trade_expired': return NotificationType.tradeExpired;
        default: return NotificationType.friendRequest;
      }
    }

    return AppNotification(
      id: json['id'] ?? '',
      type: parseType(json['type']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }
}

/// Notification service stub for future Firebase Cloud Messaging integration
///
/// Architecture ready for FCM:
/// 1. Add firebase_messaging and firebase_core to pubspec.yaml
/// 2. Configure Firebase project and download config files
/// 3. Replace stub methods with actual FCM implementation
/// 4. Store device tokens in server database
class NotificationService extends ChangeNotifier {
  final String _baseUrl;
  final String _userId;

  List<AppNotification> _notifications = [];
  String? _deviceToken;
  bool _isInitialized = false;

  NotificationService({
    required String baseUrl,
    required String userId,
  })  : _baseUrl = baseUrl,
        _userId = userId;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isInitialized => _isInitialized;

  /// Initialize notification service
  /// Stub: In production, initialize Firebase and request permissions
  Future<void> initialize() async {
    debugPrint('[NotificationService] Initializing (stub)...');

    // TODO: Replace with Firebase initialization
    // await Firebase.initializeApp();
    // final messaging = FirebaseMessaging.instance;
    //
    // NotificationSettings settings = await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );
    //
    // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   _deviceToken = await messaging.getToken();
    //   await _registerDeviceToken();
    // }

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized (stub mode)');
    notifyListeners();
  }

  /// Register device token with server
  /// Stub: Logs token, in production sends to server
  Future<void> _registerDeviceToken() async {
    if (_deviceToken == null) return;

    debugPrint('[NotificationService] Registering device token: $_deviceToken');

    // TODO: Send token to server
    // await http.post(
    //   Uri.parse('$_baseUrl/api/notifications/register'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'userId': _userId,
    //     'deviceToken': _deviceToken,
    //     'platform': Platform.isIOS ? 'ios' : 'android',
    //   }),
    // );
  }

  /// Send push notification (called from server, this is client-side simulation)
  /// Stub: Logs notification payload
  static void sendPushNotification({
    required String toUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    debugPrint('[NotificationService] STUB - Would send push notification:');
    debugPrint('  To: $toUserId');
    debugPrint('  Title: $title');
    debugPrint('  Body: $body');
    debugPrint('  Data: $data');

    // TODO: In production, this is handled server-side via FCM
    // Server would call:
    // POST https://fcm.googleapis.com/fcm/send
    // with device token and notification payload
  }

  /// Add local notification (for in-app display)
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Create and add notification from trade event
  void notifyTradeRequest(String fromUsername, String tradeId) {
    addNotification(AppNotification(
      id: 'trade_$tradeId',
      type: NotificationType.tradeRequest,
      title: 'Trade Request',
      body: '$fromUsername wants to trade with you!',
      data: {'trade_id': tradeId},
      createdAt: DateTime.now(),
    ));
  }

  void notifyTradeAccepted(String fromUsername, String tradeId) {
    addNotification(AppNotification(
      id: 'trade_accepted_$tradeId',
      type: NotificationType.tradeAccepted,
      title: 'Trade Accepted!',
      body: '$fromUsername accepted your trade request.',
      data: {'trade_id': tradeId},
      createdAt: DateTime.now(),
    ));
  }

  void notifyTradeDeclined(String fromUsername, String tradeId) {
    addNotification(AppNotification(
      id: 'trade_declined_$tradeId',
      type: NotificationType.tradeDeclined,
      title: 'Trade Declined',
      body: '$fromUsername declined your trade request.',
      data: {'trade_id': tradeId},
      createdAt: DateTime.now(),
    ));
  }

  void notifyFriendRequest(String fromUsername, String requestId) {
    addNotification(AppNotification(
      id: 'friend_$requestId',
      type: NotificationType.friendRequest,
      title: 'Friend Request',
      body: '$fromUsername wants to be your friend!',
      data: {'request_id': requestId},
      createdAt: DateTime.now(),
    ));
  }

  void notifyFriendAccepted(String username) {
    addNotification(AppNotification(
      id: 'friend_accepted_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.friendAccepted,
      title: 'Friend Added!',
      body: '$username is now your friend.',
      createdAt: DateTime.now(),
    ));
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );
    notification.isRead = true;
    notifyListeners();
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Remove specific notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }
}
