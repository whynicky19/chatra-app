import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/l10n_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/classes/class_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final api = ApiService(baseUrl: 'http://10.0.2.2:8000');
  final auth = AuthProvider(api);
  final theme = ThemeProvider();
  final l10n = L10n();

  Future.wait([auth.init(), theme.init(), l10n.init()]).then((_) {
    api.onUnauthorized = () => auth.logout();
  });

  runApp(MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<ThemeProvider>.value(value: theme),
      ChangeNotifierProvider<L10n>.value(value: l10n),
    ],
    child: ChatraApp(),
  ));
}

class ChatraApp extends StatelessWidget {
  const ChatraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Chatra', debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      home: const _AuthGate(),
      onGenerateRoute: (s) {
        switch (s.name) {
          case '/class': return MaterialPageRoute(builder: (_) => ClassDetailScreen(classId: s.arguments as int));
          default: return MaterialPageRoute(builder: (_) => const _AuthGate());
        }
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    // Гарантируем минимум 2.5 секунды показа splash
    Future.delayed(Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Показываем splash пока: auth не загрузился ИЛИ минимальное время не прошло
    if (!auth.initialized || !_splashDone) return const _Splash();

    // Плавный переход от splash к контенту
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      child: auth.isAuthenticated
          ? const MainShell(key: ValueKey('main'))
          : const _AuthNavigator(key: ValueKey('auth')),
    );
  }
}

// Отдельный Navigator только для auth экранов
class _AuthNavigator extends StatefulWidget {
  const _AuthNavigator({super.key});
  @override
  State<_AuthNavigator> createState() => _AuthNavigatorState();
}

class _AuthNavigatorState extends State<_AuthNavigator> {
  bool _showRegister = false;

  void _goRegister() => setState(() => _showRegister = true);
  void _goLogin() => setState(() => _showRegister = false);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _showRegister
          ? RegisterScreen(key: const ValueKey('register'), onGoLogin: _goLogin)
          : LoginScreen(key: const ValueKey('login'), onGoRegister: _goRegister),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Logo: scale + fade in
    _logoCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    // Text: slide up + fade in (delayed)
    _textCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );

    // Pulse glow behind logo
    _pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    // Progress bar
    _progressCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1800))
      ..repeat();

    // Stagger the animations
    _logoCtrl.forward();
    Future.delayed(Duration(milliseconds: 400), () {
      if (mounted) _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A1214) : Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated logo with pulse glow ──
            AnimatedBuilder(
              animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
              builder: (_, __) {
                final pulse = _pulseCtrl.value;
                return FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: C.teal.withOpacity(0.08 + pulse * 0.1),
                            blurRadius: 40 + pulse * 20,
                            spreadRadius: 4 + pulse * 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo-icon.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 28),

            // ── Animated text ──
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      'Chatra',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: C.teal,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Education Platform',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Color(0xFF7AABB5) : Color(0xFF7AABB5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 48),

            // ── Minimal loading indicator ──
            FadeTransition(
              opacity: _textFade,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: C.teal.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}