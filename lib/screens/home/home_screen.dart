import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/l10n_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/toast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return; setState(() => _loading = true);
    try { _posts = await context.read<ApiService>().getPosts(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _classes {
    return _posts.where((p) { try { return jsonDecode(p['body'])['type'] == 'class'; } catch (_) { return false; } })
      .map((p) { try { final b = jsonDecode(p['body']); return {...p as Map<String, dynamic>, ...b as Map<String, dynamic>, 'title': p['title']}; } catch (_) { return p as Map<String, dynamic>; } }).toList();
  }

  int _lectureCount(int id) => _posts.where((p) => (p['title'] ?? '').startsWith('[LECTURE][$id]')).length;

  String _code(int id) { const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; var s = ''; var n = id * 1337 + 42; for (var i = 0; i < 6; i++) { s += c[n % c.length]; n = n ~/ c.length + id * 7; } return s.substring(0, 6); }

  static const _grads = [[Color(0xFF006475), Color(0xFF009AAF)], [Color(0xFF0C4A6E), Color(0xFF0369A1)], [Color(0xFF134E4A), Color(0xFF0D9488)], [Color(0xFF312E81), Color(0xFF4338CA)], [Color(0xFF1E3A5F), Color(0xFF2563EB)]];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = context.watch<L10n>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: SafeArea(child: RefreshIndicator(color: C.teal, onRefresh: _load, child: CustomScrollView(slivers: [
        // Header
        SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('classes'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text(l.t('classes_sub'), style: TextStyle(fontSize: 13, color: C.text4, fontStyle: FontStyle.italic)),
          SizedBox(height: 14),
          Row(children: [
            if (auth.isTeacher) ...[
              Expanded(child: OutlinedButton.icon(icon: Icon(Icons.add, size: 16), label: Text(l.t('create_class')),
                onPressed: () => _showCreateClass(),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)))),
              SizedBox(width: 10),
            ],
            Expanded(child: ElevatedButton.icon(icon: Icon(Icons.vpn_key_rounded, size: 16, color: Colors.white), label: Text(l.t('join_code')),
              onPressed: _showJoinDialog,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)))),
          ]),
        ]))),

        // Class cards
        if (_loading) SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: C.teal)))
        else if (_classes.isEmpty) SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: C.tealLt, borderRadius: BorderRadius.circular(20)), child: Icon(Icons.menu_book_rounded, color: C.teal, size: 32)),
          SizedBox(height: 16), Text('No classes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text3)),
          SizedBox(height: 16), ElevatedButton(onPressed: _showJoinDialog, child: Text('Join by Code')),
        ])))
        else SliverPadding(padding: EdgeInsets.fromLTRB(16, 8, 16, 90), sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
          final cls = _classes[i];
          final id = cls['id'] as int;
          final colors = _grads[id % _grads.length];
          final coverImg = cls['cover_image'];
          final teacherName = cls['teacher_name'] ?? '';
          final group = cls['group'] ?? '';
          final desc = cls['description'] ?? '';

          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/class', arguments: id),
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Cover image
                ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(height: 160, width: double.infinity, child: Stack(fit: StackFit.expand, children: [
                    // Image or gradient
                    if (coverImg != null && coverImg.toString().startsWith('data:'))
                      Builder(builder: (_) { try { return Image.memory(base64Decode(coverImg.toString().split(',').last), fit: BoxFit.cover); } catch (_) { return Container(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))); } })
                    else if (coverImg != null)
                      Image.network(coverImg, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))))
                    else
                      Container(decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight))),
                    // Code chip
                    Positioned(top: 10, left: 10, child: GestureDetector(
                      onTap: () { Clipboard.setData(ClipboardData(text: _code(id))); showToast(context, 'Code copied: ${_code(id)}'); },
                      child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.copy, size: 12, color: Colors.white70), SizedBox(width: 4), Text(_code(id), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2))])))),
                    // Edit button for teachers
                    if (auth.isTeacher)
                      Positioned(top: 10, right: 10, child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/class', arguments: id),
                        child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle), child: Icon(Icons.edit, size: 16, color: Colors.white70)))),
                  ]))),
                // Body
                Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(cls['title'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: C.tealLt, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.menu_book, size: 18, color: C.teal)),
                  ]),
                  if (group.isNotEmpty) Padding(padding: EdgeInsets.only(top: 4), child: Text(group, style: TextStyle(fontSize: 13, color: C.text4))),
                  if (teacherName.isNotEmpty) Padding(padding: EdgeInsets.only(top: 4), child: Row(children: [Icon(Icons.person_outline, size: 14, color: C.teal), SizedBox(width: 4), Text(teacherName, style: TextStyle(fontSize: 13, color: C.text3, fontWeight: FontWeight.w500))])),
                  Padding(padding: EdgeInsets.only(top: 4), child: Row(children: [Icon(Icons.access_time, size: 14, color: C.text4), SizedBox(width: 4), Text('${_lectureCount(id)} lessons', style: TextStyle(fontSize: 13, color: C.text4))])),
                  SizedBox(height: 10),
                  Row(children: [
                    Text('Open course →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.teal, fontStyle: FontStyle.italic)),
                    Spacer(),
                    if (auth.isTeacher) GestureDetector(
                      onTap: () async {
                        final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                          title: Text('Удалить класс?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Нет')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Да'))],
                        ));
                        if (ok == true) { try { await context.read<ApiService>().deletePost(id); _load(); showToast(context, 'Deleted'); } catch (_) {} }
                      },
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3))),
                        child: Icon(Icons.delete_outline, size: 18, color: C.text4))),
                  ]),
                ])),
              ]),
            ),
          );
        }, childCount: _classes.length))),
      ]))),
    );
  }

  void _showJoinDialog() {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 24),
          Container(width: 64, height: 64, decoration: BoxDecoration(color: C.tealLt, borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.vpn_key_rounded, color: C.teal, size: 30)),
          SizedBox(height: 16),
          Text('Join by Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('Ask your teacher for the 6-digit code', style: TextStyle(fontSize: 14, color: C.text4)),
          SizedBox(height: 24),
          TextField(controller: ctrl, textAlign: TextAlign.center, maxLength: 6, textCapitalization: TextCapitalization.characters,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10, color: C.teal),
            decoration: InputDecoration(counterText: '', hintText: '------', hintStyle: TextStyle(letterSpacing: 10, color: C.text4.withOpacity(0.3)))),
          SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () {
              final code = ctrl.text.toUpperCase();
              final found = _classes.where((c) => _code(c['id']) == code).toList();
              if (found.isNotEmpty) { Navigator.pop(ctx); Navigator.pushNamed(context, '/class', arguments: found.first['id']); showToast(context, 'Joined ${found.first['title']}'); }
              else showToast(context, 'Class not found', error: true);
            },
            child: Text('Join Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  void _showCreateClass() {
    final nameC = TextEditingController(), descC = TextEditingController(), teacherC = TextEditingController(), groupC = TextEditingController(), periodC = TextEditingController();
    String? coverB64;
    showDialog(context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: Column(children: [
            // Header
            Padding(padding: EdgeInsets.fromLTRB(24, 20, 16, 0), child: Row(children: [
              Text('Создать класс', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Spacer(),
              IconButton(icon: Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(ctx)),
            ])),
            Expanded(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, 16, 24, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Cover
              _fieldLabel3('ОБЛОЖКА КЛАССА'),
              GestureDetector(onTap: () async {
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
                if (img != null) { final bytes = await img.readAsBytes(); setS(() => coverB64 = 'data:image/jpeg;base64,${base64Encode(bytes)}'); }
              }, child: Container(height: 160, width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: C.teal.withOpacity(0.3), width: 1.5, strokeAlign: BorderSide.strokeAlignCenter), color: coverB64 != null ? null : C.tealLt.withOpacity(0.3)),
                child: coverB64 != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(base64Decode(coverB64!.split(',').last), fit: BoxFit.cover, width: double.infinity))
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: C.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.image_outlined, size: 26, color: C.teal)), SizedBox(height: 10), Text('Нажмите для загрузки', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.teal)), Text('JPG, PNG', style: TextStyle(fontSize: 12, color: C.text4))]))),
              SizedBox(height: 20),
              _fieldLabel3('НАЗВАНИЕ КЛАССА *'), TextField(controller: nameC, decoration: InputDecoration(hintText: 'Например: Математика 10А')),
              SizedBox(height: 16), _fieldLabel3('ОПИСАНИЕ'), TextField(controller: descC, decoration: InputDecoration(hintText: 'Краткое описание курса'), maxLines: 3),
              SizedBox(height: 16), _fieldLabel3('ПЕРИОД'), TextField(controller: periodC, decoration: InputDecoration(hintText: 'Например: 2024-2025')),
              SizedBox(height: 16), _fieldLabel3('УЧИТЕЛЬ / ПРЕПОДАВАТЕЛЬ'), TextField(controller: teacherC, decoration: InputDecoration(hintText: 'Ваше имя')),
              SizedBox(height: 16), _fieldLabel3('ГРУППА'), TextField(controller: groupC, decoration: InputDecoration(hintText: 'Например: ИСУ-21')),
              SizedBox(height: 24),
            ]))),
            // Bottom buttons
            Padding(padding: EdgeInsets.fromLTRB(24, 8, 24, 20), child: Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена'), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)))),
              SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () async {
                if (nameC.text.trim().isEmpty) return;
                try {
                  await context.read<ApiService>().createPost(nameC.text.trim(), jsonEncode({
                    'type': 'class', 'description': descC.text.trim(), 'teacher_name': teacherC.text.trim(), 'group': groupC.text.trim(), 'period': periodC.text.trim(),
                    if (coverB64 != null) 'cover_image': coverB64,
                  }));
                  Navigator.pop(ctx); _load(); showToast(context, 'Class created');
                } catch (_) { showToast(context, 'Error', error: true); }
              }, child: Text('Создать'), style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)))),
            ])),
          ]),
        ),
      )));
  }

  Widget _fieldLabel3(String s) => Padding(padding: EdgeInsets.only(bottom: 8), child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.teal, letterSpacing: 1)));
}
