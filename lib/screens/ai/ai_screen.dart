import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _loading = false;
  late AnimationController _pulseCtrl;

  final _tips = [
    {'icon': Icons.menu_book_rounded, 'text': 'Объясни материал'},
    {'icon': Icons.key_rounded, 'text': 'Ключевые понятия'},
    {'icon': Icons.assignment_outlined, 'text': 'Помощь с заданием'},
    {'icon': Icons.error_outline, 'text': 'Частые ошибки'},
  ];

  @override
  void initState() { super.initState(); _pulseCtrl = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(reverse: true); }
  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  void _send([String? override]) async {
    final text = override ?? _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    HapticFeedback.lightImpact();
    setState(() { _msgs.add({'role': 'user', 'text': text}); _loading = true; });
    _ctrl.clear();
    _scrollDown();
    try {
      final api = context.read<ApiService>();
      final apiMsgs = <Map<String, dynamic>>[
        {'role': 'system', 'content': 'Ты AI-ассистент образовательной платформы Chatra. Отвечай на русском языке.'},
        ..._msgs.map((m) => {'role': m['role']!, 'content': m['text']!}),
      ];
      final data = await api.aiChat(apiMsgs);
      setState(() => _msgs.add({'role': 'assistant', 'text': data['content'] ?? 'Нет ответа'}));
    } catch (e) {
      setState(() => _msgs.add({'role': 'assistant', 'text': _parseError(e)}));
    }
    setState(() => _loading = false);
    _scrollDown();
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('503')) return 'AI сервис не настроен на сервере';
    if (e.toString().contains('429')) return 'Слишком много запросов';
    return 'Не удалось получить ответ';
  }

  void _scrollDown() {
    Future.delayed(Duration(milliseconds: 100), () { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.easeOut); });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: SafeArea(child: Column(children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: surface),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [C.teal.withOpacity(0.2), C.tealDk.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.auto_awesome, color: C.teal, size: 22)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Ассистент', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Спросите что угодно', style: TextStyle(fontSize: 12, color: C.text4)),
            ]),
            Spacer(),
            if (_msgs.isNotEmpty) IconButton(icon: Icon(Icons.delete_outline, color: C.text4, size: 20), onPressed: () => setState(() => _msgs.clear())),
            Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: C.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: C.green, shape: BoxShape.circle)), SizedBox(width: 4), Text('Онлайн', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.green))])),
          ]),
        ),
        // Body
        Expanded(child: _msgs.isEmpty ? _emptyState(isDark) : _messageList(isDark)),
        // Input
        Container(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 90),
          decoration: BoxDecoration(color: surface),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: adaptiveSurface2(context), borderRadius: BorderRadius.circular(24)),
              child: TextField(controller: _ctrl,
                decoration: InputDecoration(hintText: 'Написать сообщение...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                onSubmitted: (_) => _send(), maxLines: 4, minLines: 1, onChanged: (_) => setState(() {})))),
            SizedBox(width: 10),
            GestureDetector(onTap: _send,
              child: Container(width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: _ctrl.text.trim().isNotEmpty && !_loading ? LinearGradient(colors: [C.teal, C.tealDk]) : null,
                  color: _ctrl.text.trim().isNotEmpty || _loading ? null : adaptiveSurface2(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _ctrl.text.trim().isNotEmpty ? [BoxShadow(color: C.teal.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))] : null),
                child: Icon(_loading ? Icons.hourglass_top : Icons.send_rounded, color: _ctrl.text.trim().isNotEmpty && !_loading ? Colors.white : C.text4, size: 20))),
          ]),
        ),
      ])),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(child: SingleChildScrollView(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) {
        final scale = 1.0 + _pulseCtrl.value * 0.08;
        return Transform.scale(scale: scale, child: Container(width: 90, height: 90,
          decoration: BoxDecoration(gradient: RadialGradient(colors: [C.teal.withOpacity(0.15), C.teal.withOpacity(0.04)], radius: 0.8), shape: BoxShape.circle),
          child: Icon(Icons.auto_awesome, color: C.teal, size: 42)));
      }),
      SizedBox(height: 20),
      Text('Готов помочь!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      SizedBox(height: 6),
      Text('Спрашивайте по материалам', style: TextStyle(fontSize: 14, color: C.teal)),
      SizedBox(height: 28),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.8,
        children: _tips.map((t) => GestureDetector(
          onTap: () => _send(t['text'] as String),
          child: Container(padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: adaptiveBorder(context))),
            child: Row(children: [Icon(t['icon'] as IconData, size: 18, color: C.teal), SizedBox(width: 8), Flexible(child: Text(t['text'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))])))).toList()),
    ])));
  }

  Widget _messageList(bool isDark) {
    return ListView.builder(
      controller: _scroll, padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _msgs.length + (_loading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _msgs.length) return _typingIndicator();
        final m = _msgs[i]; final isUser = m['role'] == 'user';

        if (isUser) {
          // User: teal pill on the right
          return Padding(padding: EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [C.teal, C.tealDk], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(6)),
                boxShadow: [BoxShadow(color: C.teal.withOpacity(0.2), blurRadius: 12, offset: Offset(0, 4))]),
              child: Text(m['text'] ?? '', style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5)))),
          ]));
        }

        // AI: no bubble, just avatar + text
        return Padding(padding: EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 32, height: 32, margin: EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [C.teal.withOpacity(0.2), C.tealDk.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.auto_awesome, size: 16, color: C.teal)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.teal)),
            SizedBox(height: 4),
            SelectableText(m['text'] ?? '', style: TextStyle(fontSize: 15, height: 1.7, color: adaptiveText1(context))),
          ])),
        ]));
      },
    );
  }

  Widget _typingIndicator() => Padding(padding: EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 32, height: 32, margin: EdgeInsets.only(top: 2),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [C.teal.withOpacity(0.2), C.tealDk.withOpacity(0.1)]), borderRadius: BorderRadius.circular(10)),
      child: Icon(Icons.auto_awesome, size: 16, color: C.teal)),
    SizedBox(width: 12),
    Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: adaptiveSurface2(context), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => _Dot(delay: i * 200)))),
  ]));
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: 800))..repeat(reverse: true);
    if (widget.delay > 0) Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => Container(
    width: 8, height: 8, margin: EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(color: C.teal.withOpacity(0.3 + _c.value * 0.7), shape: BoxShape.circle)));
}
