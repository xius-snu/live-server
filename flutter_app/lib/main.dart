import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'shells/survival_shell.dart';
import 'services/user_service.dart';
import 'services/game_service.dart';
import 'services/audio_service.dart';
import 'services/marketplace_service.dart';
import 'services/event_service.dart';
import 'services/leaderboard_service.dart';
import 'services/guild_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProxyProvider<UserService, MarketplaceService>(
          create: (_) => MarketplaceService(
            baseUrl: 'https://live-server-4c3n.onrender.com',
            userIdGetter: () => null,
          ),
          update: (_, user, prev) => prev!
            ..baseUrl = user.baseUrl
            ..userIdGetter = () => user.userId,
        ),
        ChangeNotifierProxyProvider<UserService, EventService>(
          create: (_) => EventService(
            baseUrl: 'https://live-server-4c3n.onrender.com',
            userIdGetter: () => null,
          ),
          update: (_, user, prev) => prev!
            ..baseUrl = user.baseUrl
            ..userIdGetter = () => user.userId,
        ),
        ChangeNotifierProxyProvider<UserService, LeaderboardService>(
          create: (ctx) => LeaderboardService(
            Provider.of<UserService>(ctx, listen: false),
          ),
          update: (_, user, prev) => prev!,
        ),
        ChangeNotifierProvider(create: (_) => GuildService()),
      ],
      child: MaterialApp(
        title: 'Rich Roller, Poor Roller',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFFE8D5B8),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE8734A),
            secondary: Color(0xFF4ADE80),
            surface: Color(0xFFE8D5B8),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const _AppRoot(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Root widget: handles splash, initialization, username setup, then mode select.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _initialized = false;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  Future<void> _init() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final gameService = Provider.of<GameService>(context, listen: false);

    await userService.init();
    await gameService.init();

    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || !_splashDone) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8D5B8),
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/loadingscreen.png',
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final userService = Provider.of<UserService>(context);
    if (!userService.hasUser) {
      return const _UsernameSetupScreen();
    }

    return const SurvivalShell();
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
      backgroundColor: const Color(0xFFE8D5B8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎨', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'Rich Roller, Poor Roller',
                style: TextStyle(
                  color: Color(0xFF6B5038),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your painter name',
                style: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.6)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B5038), fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter username',
                  hintStyle: TextStyle(color: const Color(0xFF6B5038).withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFFD5C4A8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFFD5C4A8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8734A)),
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
                    backgroundColor: const Color(0xFFE8734A),
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
