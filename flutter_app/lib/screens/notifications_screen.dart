import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/trade_service.dart';
import '../services/friend_service.dart';
import '../widgets/shape_icon.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final tradeService = Provider.of<TradeService>(context, listen: false);
    final friendService = Provider.of<FriendService>(context, listen: false);
    await Future.wait([
      tradeService.loadTrades(),
      friendService.loadPendingRequests(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, _) {
              if (notificationService.unreadCount > 0) {
                return TextButton(
                  onPressed: () => notificationService.markAllAsRead(),
                  child: const Text('Mark all read', style: TextStyle(color: Colors.cyanAccent)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer3<TradeService, FriendService, NotificationService>(
        builder: (context, tradeService, friendService, notificationService, _) {
          final pendingTrades = tradeService.pendingIncoming;
          final pendingFriends = friendService.pendingRequests;
          final notifications = notificationService.notifications;

          final hasContent = pendingTrades.isNotEmpty ||
              pendingFriends.isNotEmpty ||
              notifications.isNotEmpty;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: hasContent
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pending Trade Requests
                        if (pendingTrades.isNotEmpty) ...[
                          _buildSectionHeader(
                            'TRADE REQUESTS',
                            pendingTrades.length,
                            Colors.purpleAccent,
                          ),
                          const SizedBox(height: 8),
                          ...pendingTrades.map((trade) => _buildTradeRequestCard(trade, tradeService)),
                          const SizedBox(height: 24),
                        ],

                        // Pending Friend Requests
                        if (pendingFriends.isNotEmpty) ...[
                          _buildSectionHeader(
                            'FRIEND REQUESTS',
                            pendingFriends.length,
                            Colors.orangeAccent,
                          ),
                          const SizedBox(height: 8),
                          ...pendingFriends.map((req) => _buildFriendRequestCard(req, friendService)),
                          const SizedBox(height: 24),
                        ],

                        // Activity/Notifications
                        if (notifications.isNotEmpty) ...[
                          _buildSectionHeader('ACTIVITY', null, Colors.white54),
                          const SizedBox(height: 8),
                          ...notifications.map((n) => _buildNotificationCard(n, notificationService)),
                        ],
                      ],
                    ),
                  )
                : _buildEmptyState(),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int? count, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTradeRequestCard(TradeRequest trade, TradeService tradeService) {
    final timeAgo = _formatTimeAgo(trade.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purpleAccent.withOpacity(0.1),
            Colors.deepPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Center(
                  child: trade.fromProfileShape != null
                      ? ShapeIcon(
                          shape: trade.fromProfileShape!,
                          size: 22,
                          color: Colors.white70,
                          strokeWidth: 2,
                        )
                      : const Icon(Icons.person, color: Colors.white54, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.fromUsername,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'wants to trade • $timeAgo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trade Details
          Row(
            children: [
              // They offer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THEY OFFER',
                      style: TextStyle(
                        color: Colors.greenAccent.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: trade.offerItems
                          .map((item) => _buildMiniItemChip(item, Colors.greenAccent))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz, color: Colors.white38),
              ),
              // They want
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THEY WANT',
                      style: TextStyle(
                        color: Colors.redAccent.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: trade.requestItems
                          .map((item) => _buildMiniItemChip(item, Colors.redAccent))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await tradeService.declineTrade(trade.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await tradeService.acceptTrade(trade.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trade completed!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniItemChip(TradeItem item, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShapeIcon(
            shape: item.shapeType,
            size: 14,
            color: Colors.white70,
            strokeWidth: 1.5,
          ),
          const SizedBox(width: 4),
          Text(
            item.shapeType,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request, FriendService friendService) {
    final timeAgo = _formatTimeAgo(request.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: request.fromProfileShape != null
                  ? ShapeIcon(
                      shape: request.fromProfileShape!,
                      size: 24,
                      color: Colors.white70,
                      strokeWidth: 2,
                    )
                  : const Icon(Icons.person, color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUsername,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wants to be friends • $timeAgo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            onPressed: () async {
              await friendService.acceptFriendRequest(request.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () async {
              await friendService.declineFriendRequest(request.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, NotificationService service) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.tradeAccepted:
        icon = Icons.check_circle;
        color = Colors.greenAccent;
        break;
      case NotificationType.tradeDeclined:
        icon = Icons.cancel;
        color = Colors.redAccent;
        break;
      case NotificationType.friendAccepted:
        icon = Icons.person_add;
        color = Colors.cyanAccent;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.white54;
    }

    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) => service.removeNotification(notification.id),
      background: Container(
        color: Colors.redAccent.withOpacity(0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      child: GestureDetector(
        onTap: () => service.markAsRead(notification.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimeAgo(notification.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            'Trade requests and friend activity will appear here',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}';
  }
}
