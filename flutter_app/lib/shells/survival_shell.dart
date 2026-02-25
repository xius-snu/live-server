import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../screens/upgrades_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/social_screen.dart';
import '../screens/profile_screen.dart';
import '../services/user_service.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';

class SurvivalShell extends StatefulWidget {
  const SurvivalShell({super.key});

  @override
  State<SurvivalShell> createState() => _SurvivalShellState();
}

class _SurvivalShellState extends State<SurvivalShell> with WidgetsBindingObserver {
  int _currentIndex = 2; // Paint tab (center)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIdleIncome());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final gameService = Provider.of<GameService>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      gameService.updateLastOnline();
      audioService.pauseBgm();
    }
    if (state == AppLifecycleState.resumed) {
      _checkIdleIncome();
      audioService.resumeBgm();
    }
  }

  void _checkIdleIncome() {
    final gameService = Provider.of<GameService>(context, listen: false);
    final offlineDuration = gameService.getOfflineDuration();

    if (offlineDuration.inSeconds > 60 && gameService.progress.idleIncomePerSecond > 0) {
      final income = gameService.applyIdleIncome(offlineDuration);
      if (income > 0 && mounted) {
        _showIdleIncomeDialog(income, offlineDuration);
      }
    }
  }

  static String _formatWithCommas(double value) {
    final whole = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return buf.toString();
  }

  void _showIdleIncomeDialog(double income, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    String timeStr;
    if (hours > 0) {
      timeStr = '${hours}h ${minutes}m';
    } else {
      timeStr = '${minutes}m';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Welcome Back!',
          style: TextStyle(color: Color(0xFF6B5038), fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Auto-Painter earned while you were away ($timeStr):',
              style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.6), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/UI/coin250.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 6),
                Text(
                  '+${_formatWithCommas(income)}',
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Nice!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: const [
                      MarketplaceScreen(),  // 0: Trade
                      SocialScreen(),       // 1: Social
                      HomeScreen(),         // 2: Paint (center)
                      UpgradesScreen(),     // 3: Level Up
                      ProfileScreen(),      // 4: Profile
                    ],
                  ),
                ),
                // Username + currency HUD (only on Paint screen)
                if (_currentIndex == 2) ...[
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 10,
                    child: Consumer2<UserService, GameService>(
                      builder: (context, us, gs, _) {
                        final name = us.username ?? '';
                        if (name.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CrossyHudTile(
                                  color: const Color(0xFF2A2A2A),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (gs.streak > 0) ...[
                                  const SizedBox(width: 4),
                                  _CrossyHudTile(
                                    color: const Color(0xFF2A2A2A),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('\u{1F525}', style: TextStyle(fontSize: 13)),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${gs.streak}',
                                          style: const TextStyle(
                                            color: Color(0xFFFF6B35),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            _CrossyHudTile(
                              color: const Color(0xFF2A2A2A),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/images/UI/coin250.png', width: 20, height: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatCurrencyValue(gs.cash),
                                    style: const TextStyle(
                                      color: Color(0xFFF5C842),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            _CrossyHudTile(
                              color: const Color(0xFF2A2A2A),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/images/UI/diamond250.png', width: 20, height: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatCurrencyValue(gs.gems.toDouble()),
                                    style: const TextStyle(
                                      color: Color(0xFFDA70D6),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Crossy Road-style nav bar
          _CrossyNavBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ],
      ),
    );
  }

  static String _formatCurrencyValue(double value) {
    final whole = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return buf.toString();
  }
}

class _CrossyHudTile extends StatelessWidget {
  final Color color;
  final Widget child;

  const _CrossyHudTile({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF111111), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CrossyNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CrossyNavBar({required this.currentIndex, required this.onTap});

  static const _icons = [
    Icons.storefront_rounded,    // 0: Trade
    Icons.public_rounded,        // 1: Social
    Icons.format_paint,          // 2: Paint (center)
    Icons.arrow_upward_rounded,  // 3: Level Up
    Icons.person,                // 4: Me
  ];

  static const _colors = [
    Color(0xFF38BDF8), // Trade: sky blue
    Color(0xFFFF6B6B), // Social: coral
    Color(0xFFF5C842), // Paint: gold
    Color(0xFF4ADE80), // Level Up: green
    Color(0xFFA855F7), // Me: purple
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: const Color(0xFF2A2A2A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: List.generate(5, (i) {
                final isActive = i == currentIndex;
                final color = _colors[i];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      color: isActive ? color : const Color(0xFF2A2A2A),
                      child: Center(
                        child: Icon(
                          _icons[i],
                          color: isActive
                              ? const Color(0xFF1A1A1A)
                              : Colors.white30,
                          size: isActive ? 30 : 26,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (bottomPad > 0)
            Container(height: bottomPad, color: const Color(0xFF2A2A2A)),
        ],
      ),
    );
  }
}
