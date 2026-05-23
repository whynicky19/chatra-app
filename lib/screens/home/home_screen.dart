import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;
  Set<int> _joinedIds = {};

  @override
  void initState() {
    super.initState();
    _loadJoined();
    _load();
  }

  void _loadJoined() {
    // In a real app, use SharedPreferences
    // For now, show all classes
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      _posts = await api.getPosts();
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _classes {
    return _posts.where((p) {
      try {
        final b = jsonDecode(p['body']);
        return b['type'] == 'class';
      } catch (_) { return false; }
    }).map((p) {
      try {
        final b = jsonDecode(p['body']);
        return {
          ...p as Map<String, dynamic>,
          ...b as Map<String, dynamic>,
          'title': p['title'],
          'cover_image': b['cover_image'],
          'description': b['description'] ?? '',
          'teacher_name': b['teacher_name'] ?? b['teacher'] ?? '',
        };
      } catch (_) { return p as Map<String, dynamic>; }
    }).toList();
  }

  int _lectureCount(int classId) {
    return _posts.where((p) => (p['title'] ?? '').startsWith('[LECTURE][$classId]')).length;
  }

  String _codeFor(int id) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var code = '';
    var n = id * 1337 + 42;
    for (var i = 0; i < 6; i++) {
      code += chars[n % chars.length];
      n = n ~/ chars.length + id * 7;
    }
    return code.substring(0, 6);
  }

  static const _coverGrads = [
    [Color(0xFF006475), Color(0xFF009AAF)],
    [Color(0xFF0C4A6E), Color(0xFF0369A1)],
    [Color(0xFF134E4A), Color(0xFF0D9488)],
    [Color(0xFF312E81), Color(0xFF4338CA)],
    [Color(0xFF1E3A5F), Color(0xFF2563EB)],
  ];

  void _showJoinDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Присоединиться', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_open, color: AppColors.teal, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Введите 6-значный код класса', style: TextStyle(fontSize: 13, color: AppColors.text3), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textAlign: TextAlign.center,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8),
              decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.toUpperCase();
              final found = _classes.where((c) => _codeFor(c['id']) == code).toList();
              if (found.isNotEmpty) {
                Navigator.pop(ctx);
                _navigateToClass(found.first['id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Присоединились к ${found.first['title']}'), backgroundColor: AppColors.teal),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Класс не найден'), backgroundColor: AppColors.red),
                );
              }
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  void _navigateToClass(int id) {
    Navigator.pushNamed(context, '/class', arguments: id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Каталог курсов', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text1)),
                                const SizedBox(height: 4),
                                Text('Исследуйте новые горизонты знаний', style: const TextStyle(fontSize: 13, color: AppColors.text4)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (auth.isTeacher)
                            OutlinedButton.icon(
                              onPressed: () => _showCreateDialog(),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Создать'),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _showJoinDialog,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                            child: const Text('По коду', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Classes grid
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
                )
              else if (_classes.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.menu_book_rounded, color: AppColors.teal, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text('Нет классов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text3)),
                        const SizedBox(height: 6),
                        const Text('Присоединитесь по коду', style: TextStyle(fontSize: 14, color: AppColors.text4)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _showJoinDialog, child: const Text('Присоединиться')),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cls = _classes[index];
                        final id = cls['id'] as int;
                        final colors = _coverGrads[id % _coverGrads.length];
                        final coverImg = cls['cover_image'];

                        return GestureDetector(
                          onTap: () => _navigateToClass(id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cover
                                Container(
                                  height: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    gradient: coverImg == null ? LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                                    image: coverImg != null ? DecorationImage(image: NetworkImage(coverImg), fit: BoxFit.cover) : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      if (auth.isTeacher)
                                        Positioned(
                                          top: 8, left: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              final code = _codeFor(id);
                                              Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Код скопирован: $code'), backgroundColor: AppColors.teal),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.copy, color: Colors.white70, size: 12),
                                                  const SizedBox(width: 4),
                                                  Text(_codeFor(id), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Body
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cls['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text1), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(cls['description'] ?? 'Нажмите для просмотра', style: const TextStyle(fontSize: 13, color: AppColors.text4), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      if ((cls['teacher_name'] ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 14, color: AppColors.teal),
                                            const SizedBox(width: 4),
                                            Text(cls['teacher_name'], style: const TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 14, color: AppColors.text4),
                                          const SizedBox(width: 4),
                                          Text('${_lectureCount(id)} уроков', style: const TextStyle(fontSize: 12, color: AppColors.text4)),
                                          const Spacer(),
                                          Text(auth.isTeacher ? 'Открыть курс →' : 'Продолжить →',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _classes.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Создать класс', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Название класса')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Описание (необязательно)'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                final api = context.read<ApiService>();
                await api.createPost(
                  nameCtrl.text.trim(),
                  jsonEncode({'type': 'class', 'description': descCtrl.text.trim()}),
                );
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Класс создан'), backgroundColor: AppColors.teal),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка создания'), backgroundColor: AppColors.red),
                );
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
