import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  bool _emailNotif = true;
  bool _aiInsights = true;

  @override
  void initState() { super.initState(); _nameCtrl.text = context.read<AuthProvider>().fullName; }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: SafeArea(child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Управляйте аккаунтом', style: TextStyle(fontSize: 14, color: C.text4)),
          SizedBox(height: 24),

          // Profile
          Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Профиль', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Обновите персональные данные', style: TextStyle(fontSize: 13, color: C.text4)),
              SizedBox(height: 20),
              Center(child: CircleAvatar(radius: 40, backgroundColor: C.teal, child: Text(auth.initials, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)))),
              SizedBox(height: 20),
              _label('ПОЛНОЕ ИМЯ'), TextField(controller: _nameCtrl, decoration: InputDecoration(hintText: 'Иванов Иван')),
              SizedBox(height: 14),
              _label('EMAIL'), TextField(enabled: false, decoration: InputDecoration(hintText: auth.email)),
              SizedBox(height: 14),
              _label('РОЛЬ'), _readonlyField(_roleLabel(auth.role)),
              if (auth.group.isNotEmpty) ...[SizedBox(height: 14), _label('ГРУППА'), _readonlyField(auth.group)],
              SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () async {
                await auth.updateProfile(_nameCtrl.text.trim());
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Сохранено'), backgroundColor: C.teal));
              }, child: Text('Сохранить'))),
            ])),
          SizedBox(height: 16),

          // Preferences
          Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.notifications_outlined, color: C.teal, size: 18), SizedBox(width: 8), Text('Настройки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))]),
              SizedBox(height: 16),
              _switchRow('Тёмная тема', 'Переключить оформление', themeProv.isDark, (_) => themeProv.toggle()),
              Divider(height: 24),
              _switchRow('Email уведомления', 'Получайте обновления на почту', _emailNotif, (v) => setState(() => _emailNotif = v)),
              Divider(height: 24),
              _switchRow('AI-аналитика', 'Персональные рекомендации', _aiInsights, (v) => setState(() => _aiInsights = v)),
            ])),
          SizedBox(height: 16),

          // Logout
          Container(decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: C.redLt, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.logout, color: C.red, size: 20)),
              title: Text('Выйти из аккаунта', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.red)),
              subtitle: Text('Вы будете перенаправлены на страницу входа', style: TextStyle(fontSize: 12, color: C.text4)),
              onTap: () => auth.logout(),
            )),
        ],
      )),
    );
  }

  Widget _label(String s) => Padding(padding: EdgeInsets.only(bottom: 6), child: Text(s, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: C.text4, letterSpacing: 1)));

  Widget _readonlyField(String text) => Container(width: double.infinity, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [Expanded(child: Text(text, style: TextStyle(fontSize: 14))), Icon(Icons.lock, size: 16, color: C.text4)]));

  Widget _switchRow(String title, String sub, bool value, Function(bool) onChanged) => Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 12, color: C.text4)),
      ])),
      Switch(value: value, onChanged: onChanged, activeColor: C.teal),
    ]));

  String _roleLabel(String r) => r == 'admin' ? 'Администратор' : r == 'teacher' ? 'Преподаватель' : 'Студент';
}
