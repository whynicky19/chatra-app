import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/toast.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<dynamic> _chats = [];
  Map<int, List<dynamic>> _messages = {};
  Map<int, List<dynamic>> _chatUsers = {};
  int? _activeChatId;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  Timer? _poller;

  static const _avatarColors = [C.teal, Color(0xFF6366F1), Color(0xFFF59E0B), Color(0xFF0891B2), Color(0xFFEC4899), Color(0xFF059669), Color(0xFFD97706), Color(0xFF64748B)];

  @override void initState() { super.initState(); _loadChats(); _poller = Timer.periodic(Duration(seconds: 5), (_) => _pollMessages()); }
  @override void dispose() { _poller?.cancel(); super.dispose(); }

  Future<void> _loadChats() async {
    if (!mounted) return; setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      _chats = await api.getChats();
      for (final c in _chats) {
        final id = c['id'] as int;
        try { _chatUsers[id] = await api.getChatUsers(id); } catch (_) {}
        try { _messages[id] = await api.getMessages(id); } catch (_) {}
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pollMessages() async {
    if (_activeChatId == null) return;
    try { final msgs = await context.read<ApiService>().getMessages(_activeChatId!); if (mounted) setState(() => _messages[_activeChatId!] = msgs); } catch (_) {}
  }

  String _chatTitle(dynamic chat) {
    final auth = context.read<AuthProvider>();
    final users = _chatUsers[chat['id']] ?? [];
    final other = users.where((u) => u['id'] != auth.userId).toList();
    if (other.isNotEmpty) return other.first['full_name'] ?? other.first['email']?.split('@').first ?? 'Chat';
    final name = chat['name'] ?? '';
    return name.startsWith('Чат с ') ? name.substring(6) : name;
  }

  String _lastPreview(int id) { final msgs = _messages[id] ?? []; if (msgs.isEmpty) return 'No messages'; return (msgs.last['content'] ?? '').toString().length > 40 ? '${msgs.last['content'].substring(0, 40)}...' : msgs.last['content'] ?? ''; }

  String _chatTime(int id) {
    final msgs = _messages[id] ?? []; if (msgs.isEmpty) return '';
    try { final d = DateTime.parse(msgs.last['created_at']); final now = DateTime.now();
      if (now.difference(d).inMinutes < 5) return 'NOW';
      if (now.difference(d).inHours < 24) return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
      if (now.difference(d).inDays == 1) return 'YESTERDAY';
      return '${d.day}.${d.month.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  void _searchUsers(String q) async {
    if (q.trim().isEmpty) { setState(() => _searchResults = []); return; }
    try {
      final all = await context.read<ApiService>().getUsers();
      final auth = context.read<AuthProvider>();
      if (mounted) setState(() { _searchResults = all.where((u) => u['id'] != auth.userId && ((u['email'] ?? '').toLowerCase().contains(q.toLowerCase()) || (u['full_name'] ?? '').toLowerCase().contains(q.toLowerCase()))).toList(); });
    } catch (_) {}
  }

  Future<void> _openDM(dynamic user) async {
    final auth = context.read<AuthProvider>();
    for (final c in _chats) { final users = _chatUsers[c['id']] ?? []; if (users.length == 2 && users.any((u) => u['id'] == user['id']) && users.any((u) => u['id'] == auth.userId)) { setState(() { _activeChatId = c['id']; _searchCtrl.clear(); _searchResults = []; }); return; } }
    try { final api = context.read<ApiService>(); final chat = await api.createChat('Чат с ${user['email']}'); await api.addChatUser(chat['id'], user['id']); _searchCtrl.clear(); _searchResults = []; await _loadChats(); setState(() => _activeChatId = chat['id']); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_activeChatId != null) return _buildChatView();
    return _buildChatList();
  }

  Widget _buildChatList() {
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      body: SafeArea(child: Column(children: [
        // Header
        Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
          Text('Chats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ])),
        SizedBox(height: 12),
        // Search
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(hintText: 'Search chats...', prefixIcon: Icon(Icons.search, size: 20, color: C.text4), contentPadding: EdgeInsets.symmetric(vertical: 12)),
          onChanged: _searchUsers,
        )),
        if (_searchResults.isNotEmpty) Container(
          constraints: BoxConstraints(maxHeight: 200), margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
          child: ListView(shrinkWrap: true, children: _searchResults.map((u) => ListTile(
            leading: CircleAvatar(radius: 20, backgroundColor: _avatarColors[(u['id'] ?? 0) % _avatarColors.length].withOpacity(0.2),
              child: Text((u['full_name'] ?? u['email'] ?? '?')[0].toUpperCase(), style: TextStyle(color: _avatarColors[(u['id'] ?? 0) % _avatarColors.length], fontWeight: FontWeight.w700))),
            title: Text(u['full_name'] ?? u['email']?.split('@').first ?? '', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(u['email'] ?? '', style: TextStyle(fontSize: 12, color: C.text4)),
            onTap: () => _openDM(u),
          )).toList())),
        SizedBox(height: 4),
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: C.teal))
          : _chats.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 56, color: C.text4),
                SizedBox(height: 12), Text('No chats yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text4)),
                SizedBox(height: 4), Text('Search for someone above', style: TextStyle(fontSize: 13, color: C.text4)),
              ]))
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 90),
                itemCount: _chats.length,
                itemBuilder: (ctx, i) {
                  final c = _chats[i]; final id = c['id'] as int;
                  final color = _avatarColors[id % _avatarColors.length];
                  final title = _chatTitle(c);
                  return GestureDetector(
                    onTap: () => setState(() => _activeChatId = id),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 4), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        CircleAvatar(radius: 26, backgroundColor: color.withOpacity(0.15),
                          child: Text(title[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18))),
                        SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          SizedBox(height: 3),
                          Text(_lastPreview(id), style: TextStyle(fontSize: 13, color: C.text4), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Text(_chatTime(id), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.text4)),
                      ]),
                    ),
                  );
                })),
      ])),
      floatingActionButton: Padding(padding: EdgeInsets.only(bottom: 76),
        child: FloatingActionButton(backgroundColor: C.teal, child: Icon(Icons.edit_outlined, color: Colors.white), onPressed: () {
          _searchCtrl.text = ''; FocusScope.of(context).requestFocus(FocusNode());
          showToast(context, 'Use the search bar to find users');
        })),
    );
  }

  Widget _buildChatView() {
    final msgs = _messages[_activeChatId] ?? [];
    final chat = _chats.firstWhere((c) => c['id'] == _activeChatId, orElse: () => {'name': 'Chat'});
    final msgCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => setState(() => _activeChatId = null)),
        title: Text(_chatTitle(chat), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Expanded(child: msgs.isEmpty
          ? Center(child: Text('No messages', style: TextStyle(color: C.text4)))
          : ListView.builder(padding: EdgeInsets.all(12), itemCount: msgs.length, itemBuilder: (ctx, i) {
              final m = msgs[i]; final isMe = m['user_id'] == auth.userId;
              return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(color: isMe ? C.teal : Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(18).copyWith(bottomRight: isMe ? Radius.circular(4) : null, bottomLeft: !isMe ? Radius.circular(4) : null)),
                  child: Text(m['content'] ?? '', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : null))));
            })),
        Container(padding: EdgeInsets.fromLTRB(12, 8, 12, 88), color: Theme.of(context).colorScheme.surface,
          child: Row(children: [
            Expanded(child: TextField(controller: msgCtrl, decoration: InputDecoration(hintText: 'Message...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              onSubmitted: (_) async { if (msgCtrl.text.trim().isEmpty) return; try { await context.read<ApiService>().sendMessage(_activeChatId!, msgCtrl.text.trim()); msgCtrl.clear(); _pollMessages(); } catch (_) {} })),
            SizedBox(width: 8),
            Container(width: 44, height: 44, decoration: BoxDecoration(color: C.teal, borderRadius: BorderRadius.circular(14)),
              child: IconButton(onPressed: () async { if (msgCtrl.text.trim().isEmpty) return; try { await context.read<ApiService>().sendMessage(_activeChatId!, msgCtrl.text.trim()); msgCtrl.clear(); _pollMessages(); } catch (_) {} },
                icon: Icon(Icons.send, color: Colors.white, size: 20))),
          ])),
      ]),
    );
  }
}
