import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/classes/class_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // ═══════════════════════════════════════════════
  // УКАЖИТЕ АДРЕС ВАШЕГО БЭКЕНДА:
  // Android эмулятор → http://10.0.2.2:8000
  // iOS симулятор    → http://localhost:8000
  // Реальный телефон → http://192.168.X.X:8000
  // ═══════════════════════════════════════════════
  final api = ApiService(baseUrl: 'http://10.0.2.2:8000');
  final auth = AuthProvider(api);

  runApp(MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: ChatraApp(),
  ));
}

class ChatraApp extends StatefulWidget {
  const ChatraApp({super.key});
  @override State<ChatraApp> createState() => _ChatraAppState();
}

class _ChatraAppState extends State<ChatraApp> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    auth.init();
    context.read<ApiService>().onUnauthorized = () => auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MaterialApp(
      title: 'Chatra', debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
    backgroundColor: C.bg,
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
