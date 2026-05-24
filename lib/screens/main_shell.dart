import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'chats/chats_screen.dart';
import 'ai/ai_screen.dart';
import 'admin/admin_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    final screens = <Widget>[
      HomeScreen(),
      ChatsScreen(),
      AiScreen(),
      if (isAdmin) AdminScreen(),
      SettingsScreen(),
    ];

    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Классы'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Чаты'),
      BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
      if (isAdmin) BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Админ'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Настройки'),
    ];

    if (_idx >= screens.length) _idx = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? Color(0xFF111B1E) : Colors.white;
    final borderColor = isDark ? Color(0xFF1E3040) : C.border;

    return Scaffold(
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 24, offset: Offset(0, -4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _idx,
            onTap: (i) => setState(() => _idx = i),
            items: items,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: C.teal,
            unselectedItemColor: isDark ? Color(0xFF4A7A86) : C.text4,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontSize: 11),
          ),
        ),
      ),
      extendBody: true,
    );
  }
}
