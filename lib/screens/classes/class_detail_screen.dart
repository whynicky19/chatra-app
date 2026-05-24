import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/toast.dart';

class ClassDetailScreen extends StatefulWidget {
  final int classId;
  const ClassDetailScreen({super.key, required this.classId});
  @override State<ClassDetailScreen> createState() => _ClassDetailState();
}

class _ClassDetailState extends State<ClassDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _posts = [];
  List<dynamic> _assignments = [];
  List<dynamic> _mySubs = [];
  Map<String, dynamic> _rating = {};
  bool _loading = true, _loadingAsg = false;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); _tabCtrl.addListener(() { if (_tabCtrl.index == 2 && _assignments.isEmpty) _loadAssignments(); }); _load(); }

  Future<void> _load() async {
    if (!mounted) return; setState(() => _loading = true);
    final api = context.read<ApiService>();
    try { _posts = await api.getPosts(); } catch (_) {}
    if (!context.read<AuthProvider>().isTeacher) {
      try { _rating = await api.getMyRating(classId: widget.classId); } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAssignments() async {
    if (!mounted) return; setState(() => _loadingAsg = true);
    final api = context.read<ApiService>();
    try {
      _assignments = await api.getAssignments(classId: widget.classId);
      if (!context.read<AuthProvider>().isTeacher) {
        try { _mySubs = await api.getMySubmissions(); } catch (_) {}
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAsg = false);
  }

  Map<String, dynamic> get _meta {
    final p = _posts.firstWhere((p) => p['id'] == widget.classId && (() { try { return jsonDecode(p['body'])['type'] == 'class'; } catch (_) { return false; } })(), orElse: () => null);
    if (p == null) return {};
    try { return jsonDecode(p['body']); } catch (_) { return {}; }
  }
  String get _title => _posts.firstWhere((p) => p['id'] == widget.classId, orElse: () => {'title': 'Класс #${widget.classId}'})?['title'] ?? '';
  List<dynamic> get _lectures => _posts.where((p) => (p['title'] ?? '').startsWith('[LECTURE][${widget.classId}]')).toList();
  List<dynamic> get _materials => _posts.where((p) => (p['title'] ?? '').startsWith('[HW][${widget.classId}]')).toList();
  String _clean(String t) => t.replaceFirst(RegExp(r'^\[(LECTURE|HW)\]\[\d+\]\s*'), '').trim();
  String _preview(dynamic p) { try { final b = jsonDecode(p['body']); return (b['content'] ?? b['description'] ?? '').replaceAll(RegExp(r'https?://\S+'), '').replaceAll(RegExp(r'\s+'), ' ').trim(); } catch (_) { return ''; } }
  String _fmtDate(String? d) { if (d == null) return ''; try { final dt = DateTime.parse(d); return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'; } catch (_) { return d; } }
  String _code(int id) { const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; var s = ''; var n = id * 1337 + 42; for (var i = 0; i < 6; i++) { s += c[n % c.length]; n = n ~/ c.length + id * 7; } return s.substring(0, 6); }
  dynamic _subFor(int aId) => _mySubs.firstWhere((s) => s['assignment_id'] == aId, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meta = _meta;
    final coverImg = meta['cover_image'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator(color: C.teal)));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(expandedHeight: 200, pinned: true, backgroundColor: C.teal,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(icon: Icon(Icons.copy, color: Colors.white70, size: 20), onPressed: () {
                final code = _code(widget.classId);
                Clipboard.setData(ClipboardData(text: code));
                showToast(context, 'Код: $code');
              }),
              if (auth.isTeacher) IconButton(icon: Icon(Icons.edit, color: Colors.white70, size: 20), onPressed: () => _editClass()),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                if (coverImg == null) Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF006475), C.teal]))),
                if (coverImg != null && !coverImg.toString().startsWith('data:'))
                  Image.network(coverImg, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.teal)),
                if (coverImg != null && coverImg.toString().startsWith('data:'))
                  Builder(builder: (_) { try { return Image.memory(base64Decode(coverImg.toString().split(',').last), fit: BoxFit.cover); } catch (_) { return Container(color: C.teal); } }),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.black54]))),
                Positioned(bottom: 50, left: 16, right: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  if (meta['description'] != null && meta['description'].toString().isNotEmpty)
                    Padding(padding: EdgeInsets.only(top: 4), child: Text(meta['description'], style: TextStyle(color: Colors.white70, fontSize: 13))),
                  SizedBox(height: 8),
                  GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: _code(widget.classId))); showToast(context, 'Код скопирован'); },
                    child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: C.tealLt.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.copy, size: 14, color: C.teal), SizedBox(width: 6), Text('Код: ', style: TextStyle(fontSize: 13, color: C.teal)), Text(_code(widget.classId), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.teal, letterSpacing: 2))]))),
                ])),
              ]),
            ),
          ),
        ],
        body: Column(children: [
          Container(color: surfaceColor, child: TabBar(controller: _tabCtrl, labelColor: C.teal, unselectedLabelColor: C.text4, indicatorColor: C.teal, labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [Tab(text: 'Лекции (${_lectures.length})'), Tab(text: 'Материалы (${_materials.length})'), Tab(text: 'Задания'), Tab(text: 'AI Chat')])),
          // Teacher action buttons below tabs
          if (auth.isTeacher) Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: surfaceColor,
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: Icon(Icons.add, size: 16), label: Text('Assignment', style: TextStyle(fontSize: 13)),
                onPressed: () => _createAssignment(),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
              )),
              SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                icon: Icon(Icons.add, size: 16, color: Colors.white), label: Text('Add', style: TextStyle(fontSize: 13)),
                onPressed: () => _showAddMenu(),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
              )),
            ]),
          ),
          Expanded(child: TabBarView(controller: _tabCtrl, children: [
            _postList(_lectures, 'lecture'),
            _postList(_materials, 'material'),
            _assignmentsTab(auth),
            _aiTab(),
          ])),
        ]),
      ),
      floatingActionButton: null,
    );
  }

  // ── Posts list ──
  Widget _postList(List<dynamic> posts, String type) {
    final surface = Theme.of(context).colorScheme.surface;
    final isTeacher = context.read<AuthProvider>().isTeacher;
    if (posts.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(type == 'lecture' ? Icons.menu_book_rounded : Icons.inventory_2_outlined, size: 48, color: C.teal),
      SizedBox(height: 12), Text(type == 'lecture' ? 'No lectures yet' : 'No materials yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text4)),
    ]));

    
    

    return ListView.builder(padding: EdgeInsets.fromLTRB(12, 4, 12, 90), itemCount: posts.length, itemBuilder: (ctx, i) {
      final p = posts[i]; final files = _extractFiles(p);
      final body = _preview(p);
      
      
      final num = posts.length - i; final ic = Icons.menu_book_rounded; final icColor = C.teal;

      return GestureDetector(
        onTap: () => _showPost(p, type),
        child: Container(
          margin: EdgeInsets.only(bottom: 14), padding: EdgeInsets.all(18),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: icColor.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(ic, color: icColor, size: 24)),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${type == 'lecture' ? 'Lecture' : 'Material'}  $num', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.teal)),
              SizedBox(height: 2),
              Text(_clean(p['title'] ?? ''), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (body.isNotEmpty) Padding(padding: EdgeInsets.only(top: 2), child: Text(body, style: TextStyle(fontSize: 13, color: C.text4), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
            if (isTeacher) ...[
              _iconBtn(Icons.edit_outlined, () => _editPost(p)),
              SizedBox(width: 4),
              _iconBtn(Icons.delete_outline, () async { try { await context.read<ApiService>().deletePost(p['id']); _load(); } catch (_) {} }),
            ],
          ]),
          SizedBox(height: 10),
          Row(children: [
            Icon(Icons.calendar_today, size: 12, color: C.text4), SizedBox(width: 4),
            Text(_fmtDate(p['created_at'] ?? ''), style: TextStyle(fontSize: 12, color: C.text4)),
            SizedBox(width: 12),
            if (files.isNotEmpty) ...[Icon(Icons.description_outlined, size: 12, color: C.text4), SizedBox(width: 3), Text('${files.length} file${files.length > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: C.text4))],
            Spacer(),
            GestureDetector(onTap: () => _showPost(p, type),
              child: Row(children: [Text('Open', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.teal)), SizedBox(width: 2), Icon(Icons.arrow_forward, size: 16, color: C.teal)])),
          ]),
          SizedBox(height: 10),
        ]),
      ));
    });
  }

  Widget _iconBtn(IconData ic, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 34, height: 34, decoration: BoxDecoration(color: C.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Icon(ic, size: 17, color: C.text4)));

  void _editPost(dynamic p) {
    final tc = TextEditingController(text: _clean(p['title'] ?? ''));
    final cc = TextEditingController(text: (() { try { return jsonDecode(p['body'])['content'] ?? ''; } catch (_) { return p['body'] ?? ''; } })());
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 20), Text('Edit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 16), TextField(controller: tc, decoration: InputDecoration(labelText: 'Title')),
          SizedBox(height: 12), TextField(controller: cc, decoration: InputDecoration(labelText: 'Content'), maxLines: 5),
          SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'))),
            SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () async {
              try {
                final prefix = (p['title'] ?? '').startsWith('[LECTURE]') ? '[LECTURE][${widget.classId}] ' : '[HW][${widget.classId}] ';
                await context.read<ApiService>().updatePost(p['id'], '$prefix${tc.text.trim()}', jsonEncode({'content': cc.text}));
                Navigator.pop(ctx); _load(); showToast(context, 'Updated');
              } catch (_) { showToast(context, 'Error', error: true); }
            }, child: Text('Save'))),
          ]),
        ])));
  }

  List<String> _extractFiles(dynamic p) {
    final body = p['body'] ?? '';
    final matches = RegExp(r'https?://[^\s"<>]+\.(pdf|doc|docx|txt|png|jpg|jpeg|pptx?|xlsx?)', caseSensitive: false).allMatches(body);
    return matches.map((m) => m.group(0)!).toList();
  }

  // ── Assignments tab ──
  Widget _assignmentsTab(AuthProvider auth) {
    if (_loadingAsg) return Center(child: CircularProgressIndicator(color: C.teal));
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return ListView(padding: EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
      // Rating card (students)
      if (!auth.isTeacher && _rating.isNotEmpty) Container(
        margin: EdgeInsets.only(bottom: 16), padding: EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF007A8E), C.teal]), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('YOUR RATING', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          SizedBox(height: 6),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PERFORMANCE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              SizedBox(height: 6),
            ])),
            SizedBox(width: 16),
            RichText(text: TextSpan(children: [
              TextSpan(text: '${(_rating['avg_score'] ?? 0).round()}', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              TextSpan(text: '/100', style: TextStyle(color: Colors.white60, fontSize: 14)),
            ])),
          ]),
          SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: Text('${(_rating['avg_percent'] ?? 0).round()}%', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
        ]),
      ),
      // Header
      Row(children: [
        Text('Lab Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Spacer(),
        Row(children: [Icon(Icons.sort, size: 14, color: C.text4), SizedBox(width: 4), Text('SORT: BY DEADLINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.text4, letterSpacing: 0.5))]),
      ]),
      SizedBox(height: 12),
      if (_assignments.isEmpty) Container(padding: EdgeInsets.all(40), child: Center(child: Column(children: [
        Icon(Icons.assignment_outlined, size: 48, color: C.teal), SizedBox(height: 8),
        Text('Нет заданий', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text3)),
      ]))),
      // Assignment cards
      ..._assignments.map((a) {
        final sub = _subFor(a['id']);
        final status = sub?['status'];
        final grade = sub?['grade'];
        final isGraded = status == 'graded';
        final isSubmitted = status == 'submitted';
        final deadline = a['deadline'];
        final isLate = deadline != null && DateTime.tryParse(deadline)?.isBefore(DateTime.now()) == true && sub == null;

        return Container(
          margin: EdgeInsets.only(bottom: 12), padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3))),
          child: InkWell(onTap: () => _showAssignment(a, sub), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(
              color: isGraded ? C.greenLt : isLate ? C.redLt : C.tealLt, borderRadius: BorderRadius.circular(12)),
              child: Icon(isGraded ? Icons.check_circle : isLate ? Icons.warning : Icons.edit_note,
                color: isGraded ? C.green : isLate ? C.red : C.teal, size: 20)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                SizedBox(width: 8),
                Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(
                  color: isGraded ? C.greenLt : isSubmitted ? C.tealLt : isLate ? C.redLt : C.surface2, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isGraded ? C.green.withOpacity(0.3) : isLate ? C.red.withOpacity(0.3) : C.border)),
                  child: Text(isGraded ? 'GRADED' : isSubmitted ? 'SUBMITTED' : isLate ? 'OVERDUE' : 'NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isGraded ? C.green : isSubmitted ? C.teal : isLate ? C.red : C.text4))),
              ]),
              if (a['description'] != null) Padding(padding: EdgeInsets.only(top: 4), child: Text(a['description'], style: TextStyle(fontSize: 13, color: C.text4), maxLines: 1, overflow: TextOverflow.ellipsis)),
              SizedBox(height: 8),
              Row(children: [
                if (deadline != null) ...[Icon(Icons.calendar_today, size: 12, color: C.text4), SizedBox(width: 4), Text(_fmtDate(deadline), style: TextStyle(fontSize: 12, color: C.text4, fontWeight: FontWeight.w500)), SizedBox(width: 12)],
                Icon(Icons.star_border, size: 14, color: C.teal), SizedBox(width: 4),
                Text('${a['max_score'] ?? 100} PTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.teal)),
                if (grade != null) ...[SizedBox(width: 12), Text('Score: ${grade['score']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.green))],
              ]),
              SizedBox(height: 6),
              Align(alignment: Alignment.centerRight, child: Text('Preview assignment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.teal))),
            ])),
          ])),
        );
      }),
    ]);
  }

  // ── AI Chat tab ──
  Widget _aiTab() => _AiChat(classId: widget.classId, className: _title);

  // ── Show post detail ──
  void _showPost(dynamic p, String type) {
    String content = ''; try { final b = jsonDecode(p['body']); content = b['content'] ?? b['description'] ?? ''; } catch (_) { content = p['body'] ?? ''; }
    final files = _extractFiles(p);
    showModalBottomSheet(context: context, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(expand: false, initialChildSize: 0.7, maxChildSize: 0.95, builder: (ctx, sc) => ListView(controller: sc, padding: EdgeInsets.all(20), children: [
        Center(child: Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2)))),
        Text(_clean(p['title'] ?? ''), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        SizedBox(height: 6), Text(_fmtDate(p['created_at'] ?? ''), style: TextStyle(fontSize: 12, color: C.text4)),
        SizedBox(height: 16), Text(content, style: TextStyle(fontSize: 14, height: 1.7)),
        if (files.isNotEmpty) ...[SizedBox(height: 16), Text('Файлы:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.text3)), SizedBox(height: 8),
          ...files.map((f) => GestureDetector(
            onTap: () async {
              final uri = Uri.parse(f);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Container(margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: C.tealLt, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [Icon(Icons.attach_file, size: 16, color: C.teal), SizedBox(width: 8), Expanded(child: Text(Uri.parse(f).pathSegments.last, style: TextStyle(fontSize: 13, color: C.teal, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)), Icon(Icons.open_in_new, size: 14, color: C.teal)])))),
        ],
      ])));
  }

  // ── Show assignment detail ──
  void _showAssignment(dynamic a, dynamic sub) {
    final tc = TextEditingController(); bool busy = false;
    final auth = context.read<AuthProvider>();
    List<dynamic> criteria = []; try { criteria = jsonDecode(a['criteria'] ?? '[]'); } catch (_) {}
    showModalBottomSheet(context: context, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => DraggableScrollableSheet(expand: false, initialChildSize: 0.8, maxChildSize: 0.95, builder: (ctx, sc) => ListView(controller: sc, padding: EdgeInsets.all(20), children: [
        Center(child: Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2)))),
        Text(a['title'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          _chip(Icons.star, '${a['max_score'] ?? 100} баллов', C.teal, C.tealLt),
          if (a['deadline'] != null) _chip(Icons.calendar_today, _fmtDate(a['deadline']), C.text4, C.surface2),
        ]),
        if (a['description'] != null) ...[SizedBox(height: 16), Text(a['description'], style: TextStyle(fontSize: 14, height: 1.6))],
        if (criteria.isNotEmpty) ...[SizedBox(height: 16), Text('Критерии оценивания', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.text3)), SizedBox(height: 8),
          ...criteria.map((c) => Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [Expanded(child: Text(c['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: C.tealLt, borderRadius: BorderRadius.circular(8)),
                child: Text('${c['weight'] ?? 0}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.teal)))])))],
        // Grade result
        if (sub?['grade'] != null) ...[SizedBox(height: 16), Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: C.greenLt, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.check_circle, size: 18, color: C.green), SizedBox(width: 8), Text('Оценка: ${sub['grade']['score']}/${a['max_score']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.green))]),
            if (sub['grade']['feedback'] != null) Padding(padding: EdgeInsets.only(top: 8), child: Text(sub['grade']['feedback'], style: TextStyle(fontSize: 13, color: C.text1, height: 1.5))),
          ]))],
        // Submit (students, not yet submitted)
        if (!auth.isTeacher && sub == null) ...[SizedBox(height: 20), Divider(), SizedBox(height: 12),
          Text('Отправить работу', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          SizedBox(height: 10), TextField(controller: tc, maxLines: 5, decoration: InputDecoration(hintText: 'Текст работы или ссылка...')),
          SizedBox(height: 12), SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: busy ? null : () async {
              if (tc.text.trim().isEmpty) return;
              setS(() => busy = true);
              try { await context.read<ApiService>().submitAssignment(a['id'], {'text_content': tc.text.trim()}); Navigator.pop(ctx); showToast(context, 'Работа отправлена!'); _loadAssignments(); }
              catch (_) { showToast(context, 'Ошибка отправки', error: true); }
              setS(() => busy = false);
            },
            child: busy ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Отправить')))],
        // Teacher: view submissions
        if (auth.isTeacher) ...[SizedBox(height: 16), SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(icon: Icon(Icons.list_alt, size: 18), label: Text('Просмотр работ'), onPressed: () => _viewSubs(a['id'])))],
        SizedBox(height: 24),
      ]))));
  }

  Widget _chip(IconData ic, String text, Color fg, Color bg) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 14, color: fg), SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg))]));

  void _viewSubs(int aId) async {
    try {
      final subs = await context.read<ApiService>().getSubmissions(aId);
      if (!mounted) return;
      final graded = subs.where((s) => s['status'] == 'graded').length;
      final pending = subs.length - graded;
      showModalBottomSheet(context: context, isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          String search = '';
          dynamic selectedSub;
          return StatefulBuilder(builder: (ctx, setS) => DraggableScrollableSheet(expand: false, initialChildSize: 0.85, maxChildSize: 0.95, builder: (ctx, sc) {
            // Detail view for selected student
            if (selectedSub != null) {
              final name = selectedSub['student_name'] ?? '#${selectedSub['student_id']}';
              final initials = name.length >= 2 ? '${name[0]}${name.split(' ').length > 1 ? name.split(' ').last[0] : name[1]}'.toUpperCase() : name[0].toUpperCase();
              final grade = selectedSub['grade'];
              final score = grade?['score'];
              final feedback = grade?['feedback'];
              final criteria = grade?['criteria'] as List<dynamic>? ?? [];
              final files = selectedSub['files'] as List<dynamic>? ?? [];
              return ListView(controller: sc, padding: EdgeInsets.all(20), children: [
                Center(child: Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2)))),
                // Back button
                GestureDetector(onTap: () => setS(() => selectedSub = null),
                  child: Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Theme.of(ctx).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back, size: 16, color: C.text4), SizedBox(width: 6), Text('Назад к списку', style: TextStyle(fontSize: 13, color: C.text4))]))),
                SizedBox(height: 16),
                // Student info
                Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: C.teal.withOpacity(0.15), child: Text(initials, style: TextStyle(color: C.teal, fontWeight: FontWeight.w800, fontSize: 14))),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(selectedSub['submitted_at'] != null ? _fmtDate(selectedSub['submitted_at']) : '', style: TextStyle(fontSize: 12, color: C.text4)),
                  ])),
                ]),
                // Attached files
                if (files.isNotEmpty || selectedSub['text_content'] != null) ...[
                  SizedBox(height: 16),
                  Text('ПРИКРЕПЛЁННЫЕ ФАЙЛЫ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.text4, letterSpacing: 1)),
                  SizedBox(height: 8),
                  if (selectedSub['text_content'] != null) Container(padding: EdgeInsets.all(12), margin: EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(color: C.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: Text(selectedSub['text_content'], style: TextStyle(fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis)),
                  ...files.map((f) => Container(padding: EdgeInsets.all(12), margin: EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(color: C.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [Icon(Icons.description, size: 18, color: C.teal), SizedBox(width: 8), Expanded(child: Text(f['filename'] ?? f.toString(), style: TextStyle(fontSize: 13, color: C.teal)))]))),
                ],
                // Score
                if (score != null) ...[
                  SizedBox(height: 20),
                  Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(ctx).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        RichText(text: TextSpan(children: [
                          TextSpan(text: '$score', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: C.teal)),
                          TextSpan(text: ' / 100', style: TextStyle(fontSize: 16, color: C.text4)),
                        ])),
                        Spacer(),
                        Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: C.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, size: 14, color: C.teal), SizedBox(width: 4), Text('ИИ-проверка', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.teal))])),
                      ]),
                      if (feedback != null) ...[
                        SizedBox(height: 12),
                        Text('ФИДБЕК', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.text4, letterSpacing: 1)),
                        SizedBox(height: 6),
                        Text(feedback, style: TextStyle(fontSize: 14, height: 1.6)),
                      ],
                    ])),
                  // Per-criteria breakdown
                  if (criteria.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text('ПО КРИТЕРИЯМ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.text4, letterSpacing: 1)),
                    SizedBox(height: 8),
                    ...criteria.map((c) => Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Theme.of(ctx).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(14)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(c['name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                          RichText(text: TextSpan(children: [
                            TextSpan(text: '${c['score'] ?? 0}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.teal)),
                            TextSpan(text: ' / ${c['max_score'] ?? c['weight'] ?? 0}', style: TextStyle(fontSize: 13, color: C.text4)),
                          ])),
                        ]),
                        if (c['feedback'] != null) Padding(padding: EdgeInsets.only(top: 6), child: Text(c['feedback'], style: TextStyle(fontSize: 13, color: C.text4, height: 1.5))),
                      ]))),
                  ],
                  SizedBox(height: 16),
                  // Re-grade button
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
                    icon: Icon(Icons.bolt, size: 18, color: Colors.white),
                    label: Text('Перепроверить ИИ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () async {
                      try { await context.read<ApiService>().aiGrade(selectedSub['id']); showToast(context, 'Перепроверка запущена'); } catch (_) { showToast(context, 'Ошибка', error: true); }
                    },
                  )),
                ] else ...[
                  SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
                    icon: Icon(Icons.bolt, size: 18, color: Colors.white),
                    label: Text('Оценить ИИ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      try { await context.read<ApiService>().aiGrade(selectedSub['id']); showToast(context, 'Оценка запущена'); } catch (_) { showToast(context, 'Ошибка', error: true); }
                    },
                  )),
                ],
                SizedBox(height: 24),
              ]);
            }
            // Student list
            final filtered = subs.where((s) => search.isEmpty || (s['student_name'] ?? '').toLowerCase().contains(search.toLowerCase())).toList();
            return ListView(controller: sc, padding: EdgeInsets.all(20), children: [
              Center(child: Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                _statBox('${subs.length}', 'Всего', C.text1),
                SizedBox(width: 8),
                _statBox('$graded', 'Проверено', C.teal),
                SizedBox(width: 8),
                _statBox('$pending', 'Ожидают', C.red),
              ]),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(hintText: 'Поиск по ФИО студента...', prefixIcon: Icon(Icons.search, size: 18, color: C.text4), contentPadding: EdgeInsets.symmetric(vertical: 10)),
                onChanged: (v) => setS(() => search = v)),
              SizedBox(height: 12),
              ...filtered.map((s) {
                final name = s['student_name'] ?? s['student_email'] ?? '#${s['student_id']}';
                final initials = name.length >= 2 ? '${name[0]}${name.split(' ').length > 1 ? name.split(' ').last[0] : name[1]}'.toUpperCase() : name[0].toUpperCase();
                final score = s['grade']?['score'];
                final isGraded = s['status'] == 'graded';
                return GestureDetector(onTap: () => setS(() => selectedSub = s),
                  child: Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      CircleAvatar(radius: 20, backgroundColor: C.teal.withOpacity(0.15), child: Text(initials, style: TextStyle(color: C.teal, fontWeight: FontWeight.w800, fontSize: 13))),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text(s['submitted_at'] != null ? _fmtDate(s['submitted_at']) : '', style: TextStyle(fontSize: 11, color: C.text4)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        if (score != null) Text('$score/100', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.teal))
                        else Text('—', style: TextStyle(fontSize: 16, color: C.text4)),
                        Text(isGraded ? 'Оценено' : 'Ожидает', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isGraded ? C.teal : C.yellow)),
                      ]),
                    ])));
              }),
            ]);
          }));
        });
    } catch (_) { showToast(context, 'Ошибка загрузки', error: true); }
  }

  Widget _statBox(String val, String label, Color color) => Expanded(child: Container(
    padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2))),
    child: Column(children: [Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)), SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 11, color: C.text4))])));

  // ── FAB menu ──
  void _showAddMenu() {
    String type = 'lecture';
    final tc = TextEditingController(), cc = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16),
          // Header
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: C.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.menu_book_rounded, color: C.teal, size: 22)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Добавить лекцию', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Учебный материал для класса', style: TextStyle(fontSize: 12, color: C.text4)),
            ])),
            IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          SizedBox(height: 20),
          // Type toggle
          Container(decoration: BoxDecoration(color: Theme.of(ctx).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: GestureDetector(onTap: () => setS(() => type = 'lecture'),
                child: Container(padding: EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: type == 'lecture' ? Theme.of(ctx).colorScheme.surface : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.menu_book, size: 16, color: type == 'lecture' ? C.teal : C.text4), SizedBox(width: 6), Text('Лекция', style: TextStyle(fontWeight: FontWeight.w600, color: type == 'lecture' ? C.teal : C.text4))])))),
              Expanded(child: GestureDetector(onTap: () => setS(() => type = 'material'),
                child: Container(padding: EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: type == 'material' ? Theme.of(ctx).colorScheme.surface : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.description_outlined, size: 16, color: type == 'material' ? C.teal : C.text4), SizedBox(width: 6), Text('Материал', style: TextStyle(fontWeight: FontWeight.w600, color: type == 'material' ? C.teal : C.text4))])))),
            ])),
          SizedBox(height: 20),
          _fieldLabel2('ТЕМА ${type == 'lecture' ? 'ЛЕКЦИИ' : 'МАТЕРИАЛА'} *'),
          TextField(controller: tc, decoration: InputDecoration(hintText: 'Например: Введение в тему...')),
          SizedBox(height: 16),
          _fieldLabel2('СОДЕРЖАНИЕ ${type == 'lecture' ? 'ЛЕКЦИИ' : 'МАТЕРИАЛА'}'),
          TextField(controller: cc, decoration: InputDecoration(hintText: 'Текст лекции, ссылки на видео...'), maxLines: 4),
          SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена'), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)))),
            SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(icon: Icon(Icons.add, size: 16, color: Colors.white), label: Text('Опубликовать'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                if (tc.text.trim().isEmpty) return;
                final prefix = type == 'lecture' ? '[LECTURE][${widget.classId}]' : '[HW][${widget.classId}]';
                try { await context.read<ApiService>().createPost('$prefix ${tc.text.trim()}', jsonEncode({'content': cc.text})); Navigator.pop(ctx); _load(); showToast(context, 'Опубликовано'); }
                catch (_) { showToast(context, 'Ошибка', error: true); }
              })),
          ]),
        ]))));
  }

  void _createPost(String type) => _showAddMenu();

  void _createAssignment() {
    final tc = TextEditingController(), dc = TextEditingController(), sc = TextEditingController(text: '100');
    DateTime? deadline;
    List<Map<String, dynamic>> criteria = [{'name': '', 'weight': 100, 'desc': ''}];

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => DraggableScrollableSheet(expand: false, initialChildSize: 0.9, maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(controller: scroll, padding: EdgeInsets.all(24), children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: C.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.edit_note, color: C.teal, size: 22)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Новое задание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Заполните данные задания', style: TextStyle(fontSize: 12, color: C.text4)),
            ])),
            IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          SizedBox(height: 24),
          _fieldLabel2('НАЗВАНИЕ ЗАДАНИЯ *'),
          TextField(controller: tc, decoration: InputDecoration(hintText: 'Например: Контрольная работа по теме...')),
          SizedBox(height: 16),
          _fieldLabel2('ОПИСАНИЕ ЗАДАНИЯ'),
          TextField(controller: dc, decoration: InputDecoration(hintText: 'Подробное описание, требования...'), maxLines: 4),
          SizedBox(height: 16),
          _fieldLabel2('МАКС. БАЛЛ'),
          TextField(controller: sc, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '100')),
          SizedBox(height: 16),
          _fieldLabel2('ДЕДЛАЙН'),
          GestureDetector(onTap: () async {
            final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365)));
            if (d != null) {
              final t = await showTimePicker(context: ctx, initialTime: TimeOfDay(hour: 23, minute: 59));
              setS(() => deadline = DateTime(d.year, d.month, d.day, t?.hour ?? 23, t?.minute ?? 59));
            }
          }, child: Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Theme.of(ctx).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Text(deadline != null ? '${deadline!.day.toString().padLeft(2, '0')}.${deadline!.month.toString().padLeft(2, '0')}.${deadline!.year} ${deadline!.hour.toString().padLeft(2, '0')}:${deadline!.minute.toString().padLeft(2, '0')}' : 'ДД.ММ.ГГГГ --:--', style: TextStyle(fontSize: 14, color: deadline != null ? null : C.text4)),
              Spacer(), Icon(Icons.calendar_today, size: 18, color: C.text4),
            ]))),
          SizedBox(height: 20),
          // Criteria
          Row(children: [
            Text('КРИТЕРИИ ОЦЕНИВАНИЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.teal, letterSpacing: 1)),
            Spacer(),
            GestureDetector(onTap: () => setS(() => criteria.add({'name': '', 'weight': 0, 'desc': ''})),
              child: Text('+ Добавить', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.teal))),
          ]),
          SizedBox(height: 4),
          Text('Сумма весов должна быть равна макс. баллу (${sc.text}/${sc.text})', style: TextStyle(fontSize: 11, color: C.text4)),
          SizedBox(height: 12),
          ...List.generate(criteria.length, (i) {
            final nameC = TextEditingController(text: criteria[i]['name']);
            final weightC = TextEditingController(text: '${criteria[i]['weight']}');
            final descC = TextEditingController(text: criteria[i]['desc'] ?? '');
            return Container(margin: EdgeInsets.only(bottom: 10), padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(ctx).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Row(children: [
                  Text('${i + 1}', style: TextStyle(fontSize: 12, color: C.text4)),
                  SizedBox(width: 8),
                  Expanded(child: TextField(controller: nameC, decoration: InputDecoration(hintText: 'Название критерия', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), onChanged: (v) => criteria[i]['name'] = v)),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: TextField(controller: weightC, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 10)), onChanged: (v) => criteria[i]['weight'] = int.tryParse(v) ?? 0)),
                  SizedBox(width: 4),
                  GestureDetector(onTap: () { if (criteria.length > 1) setS(() => criteria.removeAt(i)); }, child: Icon(Icons.close, size: 16, color: C.red)),
                ]),
                SizedBox(height: 6),
                TextField(controller: descC, decoration: InputDecoration(hintText: 'Описание (необязательно)', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), onChanged: (v) => criteria[i]['desc'] = v),
              ]));
          }),
          SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена'), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)))),
            SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(icon: Icon(Icons.add, size: 16, color: Colors.white), label: Text('Создать задание'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                if (tc.text.trim().isEmpty) return;
                try { await context.read<ApiService>().createAssignment({
                  'class_id': widget.classId, 'title': tc.text.trim(), 'description': dc.text.trim(),
                  'max_score': int.tryParse(sc.text) ?? 100,
                  'criteria': criteria.where((c) => c['name'].toString().isNotEmpty).map((c) => {'name': c['name'], 'weight': c['weight'], 'description': c['desc']}).toList(),
                  if (deadline != null) 'deadline': deadline!.toIso8601String(),
                }); Navigator.pop(ctx); _loadAssignments(); showToast(context, 'Задание создано'); }
                catch (_) { showToast(context, 'Ошибка', error: true); }
              })),
          ]),
          SizedBox(height: 24),
        ]))));
  }

  Widget _fieldLabel2(String s) => Padding(padding: EdgeInsets.only(bottom: 8), child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.teal, letterSpacing: 1)));

  void _editClass() {
    final meta = _meta;
    final tc = TextEditingController(text: _title), dc = TextEditingController(text: meta['description'] ?? ''), tn = TextEditingController(text: meta['teacher_name'] ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Редактировать класс', style: TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: tc, decoration: InputDecoration(labelText: 'Название')), SizedBox(height: 12),
        TextField(controller: dc, decoration: InputDecoration(labelText: 'Описание'), maxLines: 3), SizedBox(height: 12),
        TextField(controller: tn, decoration: InputDecoration(labelText: 'Имя учителя')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена')),
        ElevatedButton(onPressed: () async {
          try {
            final post = _posts.firstWhere((p) => p['id'] == widget.classId, orElse: () => null);
            if (post == null) return;
            var body = <String, dynamic>{}; try { body = jsonDecode(post['body']); } catch (_) {}
            body['type'] = 'class'; body['description'] = dc.text.trim(); body['teacher_name'] = tn.text.trim();
            await context.read<ApiService>().updatePost(widget.classId, tc.text.trim(), jsonEncode(body));
            Navigator.pop(ctx); _load(); showToast(context, 'Класс обновлён');
          } catch (_) { showToast(context, 'Ошибка', error: true); }
        }, child: Text('Сохранить'))],
    ));
  }

  @override void dispose() { _tabCtrl.dispose(); super.dispose(); }
}

// ── AI Chat widget ──
class _AiChat extends StatefulWidget {
  final int classId; final String className;
  const _AiChat({required this.classId, required this.className});
  @override State<_AiChat> createState() => _AiChatState();
}
class _AiChatState extends State<_AiChat> {
  final _ctrl = TextEditingController(), _scroll = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _loading = false;

  void _send() async {
    final text = _ctrl.text.trim(); if (text.isEmpty || _loading) return;
    setState(() { _msgs.add({'role': 'user', 'text': text}); _loading = true; }); _ctrl.clear();
    Future.delayed(Duration(milliseconds: 100), () { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Duration(milliseconds: 200), curve: Curves.easeOut); });
    try {
      final api = context.read<ApiService>();
      final apiMsgs = <Map<String, dynamic>>[
        {'role': 'system', 'content': 'Ты AI-ассистент курса "${widget.className}". Отвечай на русском.'},
        ..._msgs.map((m) => {'role': m['role']!, 'content': m['text']!}),
      ];
      final data = await api.aiChat(apiMsgs, classId: widget.classId);
      setState(() => _msgs.add({'role': 'assistant', 'text': data['content'] ?? 'Нет ответа'}));
    } catch (_) { setState(() => _msgs.add({'role': 'assistant', 'text': 'Ошибка соединения'})); }
    if (mounted) setState(() => _loading = false);
  }

  @override Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: _msgs.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 60, height: 60, decoration: BoxDecoration(color: C.tealLt, borderRadius: BorderRadius.circular(18)), child: Icon(Icons.auto_awesome, color: C.teal, size: 28)), SizedBox(height: 12), Text('AI Ассистент', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text3))]))
        : ListView.builder(controller: _scroll, padding: EdgeInsets.all(12), itemCount: _msgs.length + (_loading ? 1 : 0), itemBuilder: (ctx, i) {
            if (i == _msgs.length) return Align(alignment: Alignment.centerLeft, child: Container(margin: EdgeInsets.only(top: 8), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(14)), child: SizedBox(width: 40, height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: C.teal)))));
            final m = _msgs[i]; final isU = m['role'] == 'user';
            return Align(alignment: isU ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(color: isU ? C.teal : C.surface2, borderRadius: BorderRadius.circular(14).copyWith(bottomRight: isU ? Radius.circular(4) : null, bottomLeft: !isU ? Radius.circular(4) : null)),
              child: SelectableText(m['text'] ?? '', style: TextStyle(fontSize: 14, color: isU ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, height: 1.5))));
          })),
      Container(padding: EdgeInsets.fromLTRB(12, 8, 12, 88), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(children: [
          Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Спросите...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: C.border)), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)), onSubmitted: (_) => _send())),
          SizedBox(width: 8),
          Container(width: 44, height: 44, decoration: BoxDecoration(color: C.teal, borderRadius: BorderRadius.circular(12)),
            child: IconButton(onPressed: _send, icon: Icon(Icons.send, color: Colors.white, size: 20))),
        ])),
    ]);
  }
}
