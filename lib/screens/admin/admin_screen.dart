import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/toast.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminState();
}

class _AdminState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _users = [];
  List<dynamic> _aiLogs = [];
  List<dynamic> _aiSummary = [];
  bool _loading = true;
  String _search = '';
  int _totalTokens = 0;

  @override void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _tabCtrl.addListener(() { if (_tabCtrl.index == 1 && _aiSummary.isEmpty) _loadAi(); }); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _users = await context.read<ApiService>().adminUsers(); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadAi() async {
    try {
      _aiSummary = await context.read<ApiService>().adminAiSummary();
      _aiLogs = await context.read<ApiService>().adminAiUsage();
      _totalTokens = 0;
      for (final s in _aiSummary) _totalTokens += (s['total_tokens'] as num? ?? 0).toInt();
      setState(() {});
    } catch (_) {}
  }

  List<dynamic> get _filtered => _users.where((u) { final q = _search.toLowerCase(); return (u['email'] ?? '').toLowerCase().contains(q) || (u['full_name'] ?? '').toLowerCase().contains(q); }).toList();

  String _fmtTokens(num n) { if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M'; if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K'; return '$n'; }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
          Icon(Icons.shield_outlined, color: C.teal, size: 22), SizedBox(width: 8),
          Text('Admin Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ])),
        SizedBox(height: 12),
        // Stats
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          _stat(Icons.people_outline, '${_users.length}', 'Users'),
          SizedBox(width: 8),
          _stat(Icons.school_outlined, '${_users.where((u) => u['role'] == 'teacher').length}', 'Teachers'),
          SizedBox(width: 8),
          _stat(Icons.person_outline, '${_users.where((u) => u['role'] == 'student').length}', 'Students'),
        ])),
        SizedBox(height: 12),
        // Tabs
        Container(margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14)),
          child: TabBar(controller: _tabCtrl, labelColor: C.teal, unselectedLabelColor: C.text4, indicatorColor: C.teal, indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: [Tab(text: 'Users'), Tab(text: 'AI Usage')])),
        SizedBox(height: 8),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [_usersTab(), _aiTab()])),
      ])),
      floatingActionButton: Padding(padding: EdgeInsets.only(bottom: 76), child: FloatingActionButton(backgroundColor: C.teal, child: Icon(Icons.person_add, color: Colors.white), onPressed: _showCreateDialog)),
    );
  }

  Widget _stat(IconData ic, String val, String label) => Expanded(child: Container(
    padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(ic, size: 18, color: C.teal), SizedBox(height: 6),
      Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(fontSize: 11, color: C.text4)),
    ])));

  Widget _usersTab() {
    return Column(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: TextField(
        decoration: InputDecoration(hintText: 'Search users...', prefixIcon: Icon(Icons.search, size: 18, color: C.text4), contentPadding: EdgeInsets.symmetric(vertical: 10)),
        onChanged: (v) => setState(() => _search = v))),
      SizedBox(height: 8),
      Expanded(child: _loading ? Center(child: CircularProgressIndicator(color: C.teal)) :
        RefreshIndicator(color: C.teal, onRefresh: _load, child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 90), itemCount: _filtered.length, itemBuilder: (ctx, i) {
            final u = _filtered[i];
            final name = u['full_name'] ?? u['email']?.split('@').first ?? '';
            return AnimatedContainer(duration: Duration(milliseconds: 200), margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(14),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                CircleAvatar(radius: 20, backgroundColor: C.teal.withOpacity(0.15), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: C.teal, fontWeight: FontWeight.w800, fontSize: 16))),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)), SizedBox(height: 2),
                  Text(u['email'] ?? '', style: TextStyle(fontSize: 12, color: C.text4)),
                ])),
                Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: u['role'] == 'admin' ? adaptiveTealLt(context) : adaptiveSurface2(context), borderRadius: BorderRadius.circular(20)),
                  child: Text(u['role'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: u['role'] == 'admin' ? C.teal : C.text4))),
                PopupMenuButton<String>(icon: Icon(Icons.more_vert, size: 20, color: C.text4), onSelected: (v) => _action(u, v), itemBuilder: (_) => [
                  PopupMenuItem(value: 'student', child: Text('Set Student')), PopupMenuItem(value: 'teacher', child: Text('Set Teacher')),
                  PopupMenuItem(value: 'admin', child: Text('Set Admin')), PopupMenuDivider(),
                  PopupMenuItem(value: u['is_active'] == false ? 'unblock' : 'block', child: Text(u['is_active'] == false ? 'Unblock' : 'Block')),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: C.red))),
                ]),
              ]));
          }))),
    ]);
  }

  Widget _aiTab() {
    final surface = Theme.of(context).colorScheme.surface;
    return ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
      // Total tokens
      Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF006475), C.teal]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.bolt, color: Colors.white, size: 24), SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Tokens', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(_fmtTokens(_totalTokens), style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          ]),
          Spacer(),
          IconButton(icon: Icon(Icons.refresh, color: Colors.white70), onPressed: _loadAi),
        ])),
      SizedBox(height: 16),
      // Per-class summary
      if (_aiSummary.isNotEmpty) ...[
        Text('By Class', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text3)), SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _aiSummary.map((s) => Container(
          width: (MediaQuery.of(context).size.width - 48) / 2, padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.teal.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.bolt, size: 14, color: C.teal), SizedBox(width: 4), Text(s['class_name'] ?? 'Class #${s['class_id'] ?? 'General'}', style: TextStyle(fontSize: 11, color: C.teal, fontWeight: FontWeight.w700))]),
            SizedBox(height: 6),
            Text(_fmtTokens(s['total_tokens'] ?? 0), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text('tokens', style: TextStyle(fontSize: 11, color: C.text4)),
            Text('${s['request_count'] ?? 0} requests', style: TextStyle(fontSize: 11, color: C.text4)),
          ]),
        )).toList()),
        SizedBox(height: 16),
      ],
      // Recent logs
      if (_aiLogs.isNotEmpty) ...[
        Text('Recent Requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text3)), SizedBox(height: 8),
        ..._aiLogs.take(20).map((l) => Container(
          margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l['user_name'] ?? l['user_email'] ?? '#${l['user_id']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(l['created_at'] ?? '', style: TextStyle(fontSize: 11, color: C.text4)),
            ])),
            Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: adaptiveTealLt(context), borderRadius: BorderRadius.circular(8)),
              child: Text('${l['total_tokens'] ?? 0} tok', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.teal))),
          ]))),
      ],
      if (_aiSummary.isEmpty && _aiLogs.isEmpty) Padding(padding: EdgeInsets.all(40), child: Center(child: Column(children: [
        Icon(Icons.bolt, size: 48, color: C.text4), SizedBox(height: 12), Text('No AI usage data', style: TextStyle(color: C.text4)),
      ]))),
    ]);
  }

  void _action(dynamic u, String action) async {
    final api = context.read<ApiService>();
    if (u['id'] == context.read<AuthProvider>().userId && ['block', 'delete'].contains(action)) return;
    try {
      switch (action) {
        case 'student': case 'teacher': case 'admin': await api.adminSetRole(u['id'], action); break;
        case 'block': await api.adminBlock(u['id']); break;
        case 'unblock': await api.adminUnblock(u['id']); break;
        case 'delete': await api.adminDelete(u['id']); break;
      }
      if (mounted) { showToast(context, 'Done'); _load(); }
    } catch (_) { if (mounted) showToast(context, 'Error', error: true); }
  }

  void _showCreateDialog() {
    final email = TextEditingController(), pw = TextEditingController(); String role = 'student';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Create User', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, decoration: InputDecoration(hintText: 'Email')), SizedBox(height: 12),
        TextField(controller: pw, obscureText: true, decoration: InputDecoration(hintText: 'Password')), SizedBox(height: 12),
        DropdownButtonFormField<String>(value: role, items: ['student', 'teacher', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setS(() => role = v!)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
        ElevatedButton(onPressed: () async {
          try { await context.read<ApiService>().adminCreateUser(email.text.trim(), pw.text, role); Navigator.pop(ctx); showToast(context, 'Created'); _load(); }
          catch (_) { showToast(context, 'Error', error: true); }
        }, child: Text('Create'))],
    )));
  }

  @override void dispose() { _tabCtrl.dispose(); super.dispose(); }
}
