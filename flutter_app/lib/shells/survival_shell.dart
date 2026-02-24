import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../screens/upgrades_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/event_screen.dart';
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
  int _currentIndex = 0;

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
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                HomeScreen(),
                UpgradesScreen(),
                MarketplaceScreen(),
                EventScreen(),
                ProfileScreen(),
              ],
            ),
          ),
          // Username + currency pills (only on Paint screen)
          if (_currentIndex == 0) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (gs.streak > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '\u{1F525}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${gs.streak}',
                                    style: const TextStyle(
                                      color: Colors.white,
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
                      const SizedBox(height: 6),
                      _CurrencyPill(
                        value: _formatCurrencyValue(gs.cash),
                        iconAsset: 'assets/images/UI/coin250.png',
                      ),
                      const SizedBox(height: 4),
                      _CurrencyPill(
                        value: _formatCurrencyValue(gs.gems.toDouble()),
                        iconAsset: 'assets/images/UI/diamond250.png',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _buildNav(),
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

  Widget _buildNav() {
    final items = [
      (Icons.format_paint, 'Paint'),
      (Icons.arrow_upward_rounded, 'Upgrades'),
      (Icons.storefront_rounded, 'Market'),
      (Icons.celebration, 'Events'),
      (Icons.person, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF6B5038),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final (icon, label) = entry.value;
              final isActive = i == _currentIndex;

              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF5C842).withOpacity(0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: isActive ? const Color(0xFFF5C842) : Colors.white60,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: isActive ? const Color(0xFFF5C842) : Colors.white60,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String value;
  final String iconAsset;

  const _CurrencyPill({required this.value, required this.iconAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconAsset,
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
