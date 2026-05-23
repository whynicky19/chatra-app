import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ClassDetailScreen extends StatefulWidget {
  final int classId;
  const ClassDetailScreen({super.key, required this.classId});
  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _posts = [];
  List<dynamic> _assignments = [];
  bool _loading = true;
  bool _loadingAssignments = false;
  Map<String, dynamic> _rating = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 2 && _assignments.isEmpty) _loadAssignments();
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      _posts = await api.getPosts();
      if (!context.read<AuthProvider>().isTeacher) {
        try { _rating = await api.getMyRating(classId: widget.classId); } catch (_) {}
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadAssignments() async {
    setState(() => _loadingAssignments = true);
    try {
      final api = context.read<ApiService>();
      _assignments = await api.getAssignments(classId: widget.classId);
    } catch (_) {}
    setState(() => _loadingAssignments = false);
  }

  Map<String, dynamic> get _classMeta {
    final post = _posts.firstWhere(
      (p) {
        if (p['id'] != widget.classId) return false;
        try { final b = jsonDecode(p['body']); return b['type'] == 'class'; } catch (_) { return false; }
      },
      orElse: () => null,
    );
    if (post == null) return {};
    try { return jsonDecode(post['body']); } catch (_) { return {}; }
  }

  String get _classTitle {
    final post = _posts.firstWhere((p) => p['id'] == widget.classId, orElse: () => null);
    return post?['title'] ?? 'Класс #${widget.classId}';
  }

  List<dynamic> get _lectures => _posts.where((p) => (p['title'] ?? '').startsWith('[LECTURE][${widget.classId}]')).toList();
  List<dynamic> get _materials => _posts.where((p) => (p['title'] ?? '').startsWith('[HW][${widget.classId}]')).toList();

  String _cleanTitle(String t) => t.replaceFirst(RegExp(r'^\[(LECTURE|HW)\]\[\d+\]\s*'), '').trim();

  String _getPreview(dynamic p) {
    try {
      final b = jsonDecode(p['body']);
      final content = b['content'] ?? b['description'] ?? '';
      final clean = content.replaceAll(RegExp(r'https?://\S+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
      return clean.length > 100 ? '${clean.substring(0, 100)}…' : clean.isEmpty ? 'Нет описания' : clean;
    } catch (_) { return 'Нет описания'; }
  }

  String _codeFor(int id) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var code = '';
    var n = id * 1337 + 42;
    for (var i = 0; i < 6; i++) { code += chars[n % chars.length]; n = n ~/ chars.length + id * 7; }
    return code.substring(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meta = _classMeta;
    final coverImg = meta['cover_image'];
    final colors = [const Color(0xFF006475), const Color(0xFF009AAF)];

    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
        : NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.teal,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                    onPressed: () {
                      final code = _codeFor(widget.classId);
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Код: $code'), backgroundColor: AppColors.teal),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(_classTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: coverImg == null ? LinearGradient(colors: colors) : null,
                      image: coverImg != null ? DecorationImage(image: NetworkImage(coverImg), fit: BoxFit.cover) : null,
                    ),
                    child: coverImg != null ? Container(color: Colors.black38) : null,
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                // Tabs
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _tabCtrl,
                    labelColor: AppColors.teal,
                    unselectedLabelColor: AppColors.text4,
                    indicatorColor: AppColors.teal,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(text: 'Лекции (${_lectures.length})'),
                      Tab(text: 'Материалы (${_materials.length})'),
                      Tab(text: 'Задания (${_assignments.length})'),
                      const Tab(text: '✨ AI'),
                    ],
                  ),
                ),
                // Student rating
                if (!auth.isTeacher && _rating.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF007A8E), AppColors.teal]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ваш рейтинг', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${(_rating['avg_score'] ?? 0).round()}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                                const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('/100', style: TextStyle(color: Colors.white60, fontSize: 14))),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${(_rating['avg_percent'] ?? 0).round()}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            Text('${_rating['graded_count'] ?? 0} оценено', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPostsList(_lectures, 'lecture'),
                      _buildPostsList(_materials, 'material'),
                      _buildAssignmentsList(),
                      _buildAiChat(),
                    ],
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: auth.isTeacher ? FloatingActionButton(
        backgroundColor: AppColors.teal,
        onPressed: () => _showCreatePostDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildPostsList(List<dynamic> posts, String type) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type == 'lecture' ? '📖' : '📦', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(type == 'lecture' ? 'Нет лекций' : 'Нет материалов', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text3)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final p = posts[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: type == 'lecture' ? AppColors.tealLight : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type == 'lecture' ? Icons.menu_book : Icons.description,
                color: type == 'lecture' ? AppColors.teal : AppColors.yellow,
                size: 20,
              ),
            ),
            title: Text(_cleanTitle(p['title'] ?? ''), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_getPreview(p), style: const TextStyle(fontSize: 12, color: AppColors.text4), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.text4),
            onTap: () => _showPostDetail(p, type),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsList() {
    if (_loadingAssignments) return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    if (_assignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('📋', style: TextStyle(fontSize: 40)), SizedBox(height: 12), Text('Нет заданий', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text3))],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _assignments.length,
      itemBuilder: (context, i) {
        final a = _assignments[i];
        final deadline = a['deadline'];
        final isLate = deadline != null && DateTime.tryParse(deadline)?.isBefore(DateTime.now()) == true;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isLate ? AppColors.redLight : AppColors.tealLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isLate ? Icons.warning : Icons.assignment, color: isLate ? AppColors.red : AppColors.teal, size: 20),
            ),
            title: Text(a['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a['description'] != null) Text(a['description'], style: const TextStyle(fontSize: 12, color: AppColors.text4), maxLines: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (deadline != null) ...[
                      Icon(Icons.calendar_today, size: 12, color: isLate ? AppColors.red : AppColors.text4),
                      const SizedBox(width: 4),
                      Text(_fmtDate(deadline), style: TextStyle(fontSize: 11, color: isLate ? AppColors.red : AppColors.text4, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.star, size: 12, color: AppColors.teal),
                    const SizedBox(width: 4),
                    Text('${a['max_score'] ?? 0} баллов', style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLate ? AppColors.redLight : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isLate ? AppColors.red.withOpacity(0.3) : AppColors.border),
              ),
              child: Text(isLate ? 'ПРОСРОЧЕНО' : 'ОТКРЫТО', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isLate ? AppColors.red : AppColors.text4)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiChat() {
    return _ClassAiChat(classId: widget.classId, className: _classTitle, posts: _posts.where((p) => (p['title'] ?? '').contains('[${widget.classId}]')).toList());
  }

  String _fmtDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) { return d; }
  }

  void _showPostDetail(dynamic post, String type) {
    String content = '';
    try { final b = jsonDecode(post['body']); content = b['content'] ?? b['description'] ?? post['body'] ?? ''; } catch (_) { content = post['body'] ?? ''; }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: type == 'lecture' ? AppColors.tealLight : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type == 'lecture' ? Icons.menu_book : Icons.description, size: 14, color: type == 'lecture' ? AppColors.teal : AppColors.yellow),
                  const SizedBox(width: 6),
                  Text(type == 'lecture' ? 'Лекция' : 'Материал', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: type == 'lecture' ? AppColors.teal : AppColors.yellow)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_cleanTitle(post['title'] ?? ''), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(_fmtDate(post['created_at'] ?? ''), style: const TextStyle(fontSize: 12, color: AppColors.text4)),
            const SizedBox(height: 16),
            Text(content, style: const TextStyle(fontSize: 14, color: AppColors.text2, height: 1.7)),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String type = 'lecture';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Добавить контент', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _typeChip('Лекция', 'lecture', type, (v) => setS(() => type = v)),
                    const SizedBox(width: 8),
                    _typeChip('Материал', 'material', type, (v) => setS(() => type = v)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Заголовок')),
                const SizedBox(height: 12),
                TextField(controller: contentCtrl, decoration: const InputDecoration(hintText: 'Содержимое'), maxLines: 5),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final prefix = type == 'lecture' ? '[LECTURE][${widget.classId}]' : '[HW][${widget.classId}]';
                try {
                  final api = context.read<ApiService>();
                  await api.createPost('$prefix ${titleCtrl.text.trim()}', jsonEncode({'content': contentCtrl.text}));
                  Navigator.pop(ctx);
                  _load();
                } catch (_) {}
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value, String selected, Function(String) onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.teal : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.text3)),
      ),
    );
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
}

// ── Class AI Chat ──
class _ClassAiChat extends StatefulWidget {
  final int classId;
  final String className;
  final List<dynamic> posts;
  const _ClassAiChat({required this.classId, required this.className, required this.posts});
  @override
  State<_ClassAiChat> createState() => _ClassAiChatState();
}

class _ClassAiChatState extends State<_ClassAiChat> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _loading = false;

  void _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _msgs.add({'role': 'user', 'text': text});
      _loading = true;
    });
    _msgCtrl.clear();
    _scrollDown();
    try {
      final api = context.read<ApiService>();
      final data = await api.aiChat(text, classId: widget.classId);
      setState(() => _msgs.add({'role': 'assistant', 'text': data['response'] ?? data['message'] ?? 'Нет ответа'}));
    } catch (e) {
      setState(() => _msgs.add({'role': 'assistant', 'text': 'Ошибка: $e'}));
    }
    setState(() => _loading = false);
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _msgs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.auto_awesome, color: AppColors.teal, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text('AI Ассистент', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text3)),
                    const SizedBox(height: 4),
                    const Text('Спросите о курсе', style: TextStyle(fontSize: 13, color: AppColors.text4)),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: _msgs.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _msgs.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                        child: const SizedBox(width: 40, height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))),
                      ),
                    );
                  }
                  final m = _msgs[i];
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.teal : AppColors.surface2,
                        borderRadius: BorderRadius.circular(14).copyWith(
                          bottomRight: isUser ? const Radius.circular(4) : null,
                          bottomLeft: !isUser ? const Radius.circular(4) : null,
                        ),
                      ),
                      child: Text(m['text'] ?? '', style: TextStyle(fontSize: 14, color: isUser ? Colors.white : AppColors.text1, height: 1.5)),
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
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Спросите что-нибудь...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _msgCtrl.text.trim().isNotEmpty ? AppColors.teal : AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _send,
                  icon: Icon(Icons.send, color: _msgCtrl.text.trim().isNotEmpty ? Colors.white : AppColors.text4, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
