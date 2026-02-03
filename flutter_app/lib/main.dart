import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/drawing_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/user_service.dart';
import 'services/friend_service.dart';
import 'services/trade_service.dart';
import 'services/notification_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserService(),
      child: Consumer<UserService>(
        builder: (context, userService, child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: userService),
              ChangeNotifierProvider(
                create: (_) => FriendService(
                  baseUrl: userService.baseUrl,
                  userId: userService.userId ?? '',
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => TradeService(
                  baseUrl: userService.baseUrl,
                  userId: userService.userId ?? '',
                  userService: userService,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => NotificationService(
                  baseUrl: userService.baseUrl,
                  userId: userService.userId ?? '',
                ),
              ),
            ],
            child: MaterialApp(
              title: 'One-Motion Draw',
              theme: ThemeData.dark().copyWith(
                primaryColor: Colors.blueGrey,
                scaffoldBackgroundColor: const Color(0xFF222222),
                colorScheme: const ColorScheme.dark(
                  primary: Colors.cyanAccent,
                  secondary: Colors.greenAccent,
                ),
              ),
              home: const AppShell(),
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}

/// Main app shell with bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize user service
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.init();

      // Initialize notification service
      if (mounted) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        await notificationService.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DrawingScreen(),
          InventoryScreen(showBackButton: false),
          FriendsScreen(),
          NotificationsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Consumer2<TradeService, FriendService>(
      builder: (context, tradeService, friendService, _) {
        // Calculate notification badge count
        final pendingTrades = tradeService.pendingIncoming.length;
        final pendingFriends = friendService.pendingRequests.length;
        final totalBadge = pendingTrades + pendingFriends;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.gesture,
                    label: 'Draw',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.grid_view_rounded,
                    label: 'Collection',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.people,
                    label: 'Friends',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.notifications,
                    label: 'Inbox',
                    badge: totalBadge,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badge = 0,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.cyanAccent : Colors.white54,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
