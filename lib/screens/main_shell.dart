import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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

    // Clamp index
    if (_idx >= screens.length) _idx = 0;

    return Scaffold(
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: C.border, width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          items: items,
        ),
      ),
    );
  }
}
