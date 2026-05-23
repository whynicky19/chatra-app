import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  bool _emailNotif = true;
  bool _aiInsights = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.fullName;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text1)),
            const SizedBox(height: 4),
            const Text('Управляйте аккаунтом', style: TextStyle(fontSize: 14, color: AppColors.text4)),
            const SizedBox(height: 24),

            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Профиль', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Обновите персональные данные', style: TextStyle(fontSize: 13, color: AppColors.text4)),
                  const SizedBox(height: 20),
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.teal,
                      child: Text(auth.initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('ПОЛНОЕ ИМЯ'),
                  const SizedBox(height: 6),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Иванов Иван')),
                  const SizedBox(height: 14),
                  _fieldLabel('EMAIL'),
                  const SizedBox(height: 6),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(hintText: auth.email, fillColor: AppColors.surface2.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('РОЛЬ'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Text(_roleLabel(auth.role), style: const TextStyle(fontSize: 14, color: AppColors.text2)),
                        const Spacer(),
                        const Icon(Icons.lock, size: 16, color: AppColors.text4),
                      ],
                    ),
                  ),
                  if (auth.group.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _fieldLabel('ГРУППА'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Text(auth.group, style: const TextStyle(fontSize: 14, color: AppColors.text2)),
                          const Spacer(),
                          const Icon(Icons.lock, size: 16, color: AppColors.text4),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await auth.updateProfile(_nameCtrl.text.trim());
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сохранено'), backgroundColor: AppColors.teal));
                      },
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preferences
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications, color: AppColors.teal, size: 18),
                      const SizedBox(width: 8),
                      const Text('Настройки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _prefRow('Email уведомления', 'Получайте обновления на почту', _emailNotif, (v) => setState(() => _emailNotif = v)),
                  const Divider(),
                  _prefRow('AI-аналитика', 'Персональные рекомендации', _aiInsights, (v) => setState(() => _aiInsights = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout, color: AppColors.red, size: 20),
                ),
                title: const Text('Выйти из аккаунта', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.red)),
                subtitle: const Text('Вы будете перенаправлены на страницу входа', style: TextStyle(fontSize: 12, color: AppColors.text4)),
                onTap: () async {
                  await auth.logout();
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text4, letterSpacing: 1));
  }

  Widget _prefRow(String title, String sub, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.text4)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.teal),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Администратор';
      case 'teacher': return 'Преподаватель';
      default: return 'Студент';
    }
  }
}
