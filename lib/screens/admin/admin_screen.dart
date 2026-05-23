import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/toast.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _users = await context.read<ApiService>().adminUsers(); } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _filtered => _users.where((u) {
    final q = _search.toLowerCase();
    return (u['email'] ?? '').toLowerCase().contains(q) || (u['full_name'] ?? '').toLowerCase().contains(q);
  }).toList();

  Color _avatarColor(int id) => [C.teal, C.tealDk, C.green, Color(0xFFD97706), C.red, Color(0xFF0891B2)][id % 6];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
          Icon(Icons.shield, color: C.teal, size: 22), SizedBox(width: 8),
          Text('Админ-панель', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.text1)),
        ])),
        SizedBox(height: 12),
        // Stats
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          _stat(Icons.people, '${_users.length}', 'Пользователей'),
          SizedBox(width: 8),
          _stat(Icons.school, '${_users.where((u) => u['role'] == 'teacher').length}', 'Учителей'),
          SizedBox(width: 8),
          _stat(Icons.person, '${_users.where((u) => u['role'] == 'student').length}', 'Студентов'),
        ])),
        SizedBox(height: 12),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: TextField(
          decoration: InputDecoration(hintText: 'Поиск пользователей...', prefixIcon: Icon(Icons.search, size: 18, color: C.text4), contentPadding: EdgeInsets.symmetric(vertical: 10)),
          onChanged: (v) => setState(() => _search = v),
        )),
        SizedBox(height: 8),
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: C.teal))
          : RefreshIndicator(color: C.teal, onRefresh: _load, child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final u = _filtered[i];
                final isActive = u['is_active'] ?? true;
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: _avatarColor(u['id'] ?? 0), child: Text((u['full_name'] ?? u['email'] ?? '?')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u['full_name'] ?? u['email']?.split('@').first ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text1)),
                      SizedBox(height: 2),
                      Text(u['email'] ?? '', style: TextStyle(fontSize: 12, color: C.text4)),
                    ])),
                    Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: u['role'] == 'admin' ? C.tealLt : C.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: u['role'] == 'admin' ? C.teal.withOpacity(0.3) : C.border)),
                      child: Text(u['role'] ?? 'student', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: u['role'] == 'admin' ? C.teal : C.text4))),
                    SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: C.text4),
                      onSelected: (v) => _action(u, v),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'student', child: Text('→ Студент')),
                        PopupMenuItem(value: 'teacher', child: Text('→ Учитель')),
                        PopupMenuItem(value: 'admin', child: Text('→ Админ')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: isActive ? 'block' : 'unblock', child: Text(isActive ? 'Заблокировать' : 'Разблокировать')),
                        PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: C.red))),
                      ],
                    ),
                  ]),
                );
              },
            )),
        ),
      ])),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.teal,
        icon: Icon(Icons.person_add, color: Colors.white),
        label: Text('Создать', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: _showCreateDialog,
      ),
    );
  }

  Widget _stat(IconData icon, String val, String label) => Expanded(child: Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
    child: Row(children: [Icon(icon, size: 18, color: C.teal), SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text1)), Text(label, style: TextStyle(fontSize: 10, color: C.text4))])]),
  ));

  void _action(dynamic u, String action) async {
    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    if (u['id'] == auth.userId && ['block', 'delete'].contains(action)) return;
    try {
      switch (action) {
        case 'student': case 'teacher': case 'admin': await api.adminSetRole(u['id'], action); break;
        case 'block': await api.adminBlock(u['id']); break;
        case 'unblock': await api.adminUnblock(u['id']); break;
        case 'delete': await api.adminDelete(u['id']); break;
      }
      if (mounted) { showToast(context, 'Готово'); _load(); }
    } catch (e) { if (mounted) showToast(context, 'Ошибка', error: true); }
  }

  void _showCreateDialog() {
    final email = TextEditingController(), pw = TextEditingController();
    String role = 'student';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Создать пользователя', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, decoration: InputDecoration(hintText: 'Email')),
        SizedBox(height: 12),
        TextField(controller: pw, obscureText: true, decoration: InputDecoration(hintText: 'Пароль')),
        SizedBox(height: 12),
        DropdownButtonFormField<String>(value: role, decoration: InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          items: ['student', 'teacher', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setS(() => role = v!)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена')),
        ElevatedButton(onPressed: () async {
          if (email.text.trim().isEmpty || pw.text.isEmpty) return;
          try {
            await context.read<ApiService>().adminCreateUser(email.text.trim(), pw.text, role);
            Navigator.pop(ctx); showToast(context, 'Создан'); _load();
          } catch (e) { showToast(context, 'Ошибка', error: true); }
        }, child: Text('Создать')),
      ],
    )));
  }
}
