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
import 'theme/app_colors.dart';

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
        ChangeNotifierProxyProvider<UserService, GameService>(
          create: (_) => GameService(),
          update: (_, user, prev) {
            final gs = prev!;
            if (user.userId != null) {
              gs.setSyncInfo(user.baseUrl, user.userId!);
            }
            return gs;
          },
        ),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProxyProvider<UserService, MarketplaceService>(
          create: (_) => MarketplaceService(
            baseUrl: 'https://live-server-4c3n.onrender.com',
            userIdGetter: () => null,
          ),
          update: (_, user, prev) {
            final svc = prev!;
            svc.baseUrl = user.baseUrl;
            svc.userIdGetter = () => user.userId;
            svc.authHeadersGetter = () => user.authHeaders;
            return svc;
          },
        ),
        ChangeNotifierProxyProvider<UserService, EventService>(
          create: (_) => EventService(
            baseUrl: 'https://live-server-4c3n.onrender.com',
            userIdGetter: () => null,
          ),
          update: (_, user, prev) {
            final svc = prev!;
            svc.baseUrl = user.baseUrl;
            svc.userIdGetter = () => user.userId;
            svc.authHeadersGetter = () => user.authHeaders;
            return svc;
          },
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
        title: 'Rich Painter, Poor Painter',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.background,
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

class _AppRootState extends State<_AppRoot> with SingleTickerProviderStateMixin {
  bool _initialized = false;
  bool _splashDone = false;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final gameService = Provider.of<GameService>(context, listen: false);

    // Start progress animation and init in parallel
    _progressController.addListener(() {
      if (mounted) setState(() {});
    });
    _progressController.forward();
    await userService.init();
    await gameService.init();
    setState(() => _initialized = true);

    // Wait for progress bar to finish if still animating
    if (_progressController.isAnimating) {
      await _progressController.forward().orCancel.catchError((_) {});
    }
    if (mounted) setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || !_splashDone) {
      final progress = _progressController.value;
      final percent = (progress * 100).toInt();
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                'assets/images/loadingscreen.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 36,
              child: Stack(
                children: [
                  // Background bar
                  Container(color: AppColors.hudDark),
                  // Progress fill
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(color: AppColors.primary),
                  ),
                  // Percent text
                  Center(
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎨', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'Rich Painter, Poor Painter',
                style: TextStyle(
                  color: AppColors.brownDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your painter name',
                style: TextStyle(color: AppColors.brownDark.withOpacity(0.6)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.brownDark, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter username',
                  hintStyle: TextStyle(color: AppColors.brownDark.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary),
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
                    backgroundColor: AppColors.primary,
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
