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

  // Init async before runApp
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
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Chatra', debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      home: !auth.initialized ? _Splash() : auth.isAuthenticated ? MainShell() : LoginScreen(),
      onGenerateRoute: (s) {
        switch (s.name) {
          case '/login': return MaterialPageRoute(builder: (_) => LoginScreen());
          case '/register': return MaterialPageRoute(builder: (_) => RegisterScreen());
          case '/home': return MaterialPageRoute(builder: (_) => MainShell());
          case '/class': return MaterialPageRoute(builder: (_) => ClassDetailScreen(classId: s.arguments as int));
          default: return MaterialPageRoute(builder: (_) => MainShell());
        }
      },
    );
  }
}

class _Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [C.teal, C.tealDk]), boxShadow: [BoxShadow(color: C.teal.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 8))]),
        child: Icon(Icons.school_rounded, color: Colors.white, size: 40)),
      SizedBox(height: 20),
      Text('Chatra', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.teal, letterSpacing: 2)),
      SizedBox(height: 24),
      SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: C.teal)),
    ])),
  );
}
