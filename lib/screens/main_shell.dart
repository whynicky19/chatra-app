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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? Color(0xFF151F23) : Colors.white;

    final screens = <Widget>[
      HomeScreen(),
      ChatsScreen(),
      AiScreen(),
      if (isAdmin) AdminScreen(),
      SettingsScreen(),
    ];

    if (_idx >= screens.length) _idx = 0;

    final icons = <_NavItem>[
      _NavItem(Icons.school_outlined, Icons.school_rounded),
      _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
      _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome),
      if (isAdmin) _NavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings),
      _NavItem(Icons.settings_outlined, Icons.settings_rounded),
    ];

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: IndexedStack(index: _idx, children: screens)),
        // Floating nav island
        Positioned(left: 16, right: 16, bottom: 16,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(icons.length, (i) {
                final sel = _idx == i;
                return GestureDetector(
                  onTap: () => setState(() => _idx = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200), curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(horizontal: sel ? 20 : 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? C.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      sel ? icons[i].active : icons[i].inactive,
                      color: sel ? Colors.white : (isDark ? Color(0xFF4A7A86) : C.text4),
                      size: 22,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }
}

class _NavItem {
  final IconData inactive;
  final IconData active;
  _NavItem(this.inactive, this.active);
}
