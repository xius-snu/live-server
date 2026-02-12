import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/upgrades_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/event_screen.dart';
import 'screens/profile_screen.dart';
import 'services/user_service.dart';
import 'services/game_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaintRollerApp());
}

class PaintRollerApp extends StatelessWidget {
  const PaintRollerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => GameService()),
      ],
      child: MaterialApp(
        title: 'Paint Roller',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE94560),
            secondary: Color(0xFF4ADE80),
            surface: Color(0xFF16213E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const AppShell(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final gameService = Provider.of<GameService>(context, listen: false);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      gameService.updateLastOnline();
    }
    if (state == AppLifecycleState.resumed) {
      _checkIdleIncome();
    }
  }

  Future<void> _init() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final gameService = Provider.of<GameService>(context, listen: false);

    await userService.init();
    await gameService.init();

    _checkIdleIncome();

    setState(() => _initialized = true);
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
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Welcome Back!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Auto-Painter earned while you were away ($timeStr):',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '+\$${income.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
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
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎨', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                'Paint Roller',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Color(0xFFE94560)),
            ],
          ),
        ),
      );
    }

    // Check if user needs to set username
    final userService = Provider.of<UserService>(context);
    if (!userService.hasUser) {
      return const _UsernameSetupScreen();
    }

    return Scaffold(
      body: Column(
        children: [
          // Currency bar
          _CurrencyBar(),
          // Content
          Expanded(
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
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
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
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: Border(
          top: BorderSide(color: const Color(0xFF2A3A5E)),
        ),
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
                    color: isActive ? const Color(0xFFE94560).withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: isActive ? const Color(0xFFE94560) : Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: isActive ? const Color(0xFFE94560) : Colors.white38,
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

class _CurrencyBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gs, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 8,
            16,
            10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            border: Border(
              bottom: BorderSide(color: const Color(0xFF2A3A5E)),
            ),
          ),
          child: Row(
            children: [
              // Cash
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💵', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '\$${_formatCash(gs.cash)}',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C842).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${gs.stars}',
                      style: const TextStyle(
                        color: Color(0xFFF5C842),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Prestige level
              Text(
                'Prestige Lv.${gs.prestigeLevel}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCash(double cash) {
    if (cash >= 1000000) return '${(cash / 1000000).toStringAsFixed(1)}M';
    if (cash >= 1000) return '${(cash / 1000).toStringAsFixed(1)}K';
    return cash.toStringAsFixed(0);
  }
}

class _UsernameSetupScreen extends StatefulWidget {
  const _UsernameSetupScreen();

  @override
  State<_UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<_UsernameSetupScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final user = Provider.of<UserService>(context, listen: false);
    await user.setUsername(_controller.text.trim());
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎨', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'Paint Roller',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your painter name',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter username',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFF2A3A5E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFF2A3A5E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE94560)),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'START PAINTING',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
