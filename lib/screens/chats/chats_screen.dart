import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<dynamic> _chats = [];
  Map<int, List<dynamic>> _messages = {};
  Map<int, List<dynamic>> _chatUsers = {};
  int? _activeChatId;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      _chats = await api.getChats();
      for (final c in _chats) {
        final id = c['id'] as int;
        try { _chatUsers[id] = await api.getChatUsers(id); } catch (_) {}
        try { _messages[id] = await api.getMessages(id); } catch (_) {}
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pollMessages() async {
    if (_activeChatId == null) return;
    try {
      final api = context.read<ApiService>();
      final msgs = await api.getMessages(_activeChatId!);
      if (mounted) setState(() => _messages[_activeChatId!] = msgs);
    } catch (_) {}
  }

  String _chatTitle(dynamic chat) {
    final auth = context.read<AuthProvider>();
    final users = _chatUsers[chat['id']] ?? [];
    final other = users.where((u) => u['id'] != auth.userId).toList();
    if (other.isNotEmpty) return other.first['full_name'] ?? other.first['email']?.split('@').first ?? 'Чат';
    final name = chat['name'] ?? '';
    return name.startsWith('Чат с ') ? name.substring(6) : name;
  }

  String _lastPreview(int id) {
    final msgs = _messages[id] ?? [];
    if (msgs.isEmpty) return 'Нет сообщений';
    final last = msgs.last;
    final content = last['content'] ?? '';
    return content.length > 45 ? '${content.substring(0, 45)}…' : content;
  }

  String _chatTime(int id) {
    final msgs = _messages[id] ?? [];
    if (msgs.isEmpty) return '';
    final last = msgs.last;
    try {
      final d = DateTime.parse(last['created_at']);
      final now = DateTime.now();
      if (now.difference(d).inDays == 0) return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
      return '${d.day}.${d.month.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  void _searchUsers(String q) async {
    if (q.trim().isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _searching = true);
    try {
      final api = context.read<ApiService>();
      final all = await api.getUsers();
      final auth = context.read<AuthProvider>();
      setState(() {
        _searchResults = all.where((u) =>
          u['id'] != auth.userId &&
          ((u['email'] ?? '').toLowerCase().contains(q.toLowerCase()) ||
           (u['full_name'] ?? '').toLowerCase().contains(q.toLowerCase()))
        ).toList();
      });
    } catch (_) {}
    setState(() => _searching = false);
  }

  Future<void> _openDM(dynamic user) async {
    final auth = context.read<AuthProvider>();
    // Check existing
    for (final c in _chats) {
      final users = _chatUsers[c['id']] ?? [];
      if (users.length == 2 && users.any((u) => u['id'] == user['id']) && users.any((u) => u['id'] == auth.userId)) {
        setState(() { _activeChatId = c['id']; _searchCtrl.clear(); _searchResults = []; });
        return;
      }
    }
    // Create new
    try {
      final api = context.read<ApiService>();
      final chat = await api.createChat('Чат с ${user['email']}');
      await api.addChatUser(chat['id'], user['id']);
      _searchCtrl.clear();
      _searchResults = [];
      await _loadChats();
      setState(() => _activeChatId = chat['id']);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_activeChatId != null) return _buildChatView();
    return _buildChatList();
  }

  Widget _buildChatList() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Чаты', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text1)),
                  const Spacer(),
                  IconButton(
                    onPressed: _showNewGroupDialog,
                    icon: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: const Icon(Icons.add, size: 18, color: AppColors.text3),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Поиск пользователей...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.text4),
                  suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { _searchCtrl.clear(); setState(() => _searchResults = []); }) : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: _searchUsers,
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                child: ListView(
                  shrinkWrap: true,
                  children: _searchResults.map((u) => ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.teal, child: Text((u['full_name'] ?? u['email'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    title: Text(u['full_name'] ?? u['email']?.split('@').first ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(u['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.text4)),
                    trailing: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.chat, size: 16, color: AppColors.teal)),
                    onTap: () => _openDM(u),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : _chats.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('💬', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Нет чатов', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text3)), Text('Найдите пользователя в поиске', style: TextStyle(fontSize: 13, color: AppColors.text4))]))
                  : ListView.builder(
                      itemCount: _chats.length,
                      itemBuilder: (context, i) {
                        final c = _chats[i];
                        final id = c['id'] as int;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.teal.withOpacity(0.2 + (id % 6) * 0.1),
                            child: Text(_chatTitle(c)[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(_chatTitle(c), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          subtitle: Text(_lastPreview(id), style: const TextStyle(fontSize: 12, color: AppColors.text4), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(_chatTime(id), style: const TextStyle(fontSize: 11, color: AppColors.text4)),
                          onTap: () => setState(() => _activeChatId = id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    final msgs = _messages[_activeChatId] ?? [];
    final chat = _chats.firstWhere((c) => c['id'] == _activeChatId, orElse: () => {'name': 'Чат'});
    final msgCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _activeChatId = null)),
        title: Text(_chatTitle(chat)),
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1, fontFamily: 'Outfit'),
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.isEmpty
              ? const Center(child: Text('Нет сообщений', style: TextStyle(color: AppColors.text4)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final isMe = m['user_id'] == auth.userId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.teal : AppColors.surface2,
                          borderRadius: BorderRadius.circular(14).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : null,
                            bottomLeft: !isMe ? const Radius.circular(4) : null,
                          ),
                        ),
                        child: Text(m['content'] ?? '', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.text1)),
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    decoration: InputDecoration(hintText: 'Сообщение...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.border)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    onSubmitted: (_) async {
                      if (msgCtrl.text.trim().isEmpty) return;
                      try {
                        final api = context.read<ApiService>();
                        await api.sendMessage(_activeChatId!, msgCtrl.text.trim());
                        msgCtrl.clear();
                        _pollMessages();
                      } catch (_) {}
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    onPressed: () async {
                      if (msgCtrl.text.trim().isEmpty) return;
                      try {
                        final api = context.read<ApiService>();
                        await api.sendMessage(_activeChatId!, msgCtrl.text.trim());
                        msgCtrl.clear();
                        _pollMessages();
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewGroupDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Новый групповой чат', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Название группы')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                final api = context.read<ApiService>();
                await api.createChat(nameCtrl.text.trim());
                Navigator.pop(ctx);
                _loadChats();
              } catch (_) {}
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
