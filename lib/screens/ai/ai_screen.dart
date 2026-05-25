import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _loading = false;

  final _tips = ['Давай пообщаемся', 'Объясни тему кратко', 'Помоги с кодом', 'Составь план урока', 'Проверь мой текст'];

  void _send([String? override]) async {
    final text = override ?? _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() { _msgs.add({'role': 'user', 'text': text}); _loading = true; });
    _ctrl.clear();
    _scrollDown();

    try {
      final api = context.read<ApiService>();
      // Build messages history for API
      final apiMsgs = <Map<String, dynamic>>[
        {'role': 'system', 'content': 'Ты AI-ассистент образовательной платформы. Отвечай на русском языке.'},
        ..._msgs.map((m) => {'role': m['role']!, 'content': m['text']!}),
      ];
      final data = await api.aiChat(apiMsgs);
      setState(() => _msgs.add({'role': 'assistant', 'text': data['content'] ?? 'Нет ответа'}));
    } catch (e) {
      setState(() => _msgs.add({'role': 'assistant', 'text': 'Ошибка: ${_parseError(e)}'}));
    }
    setState(() => _loading = false);
    _scrollDown();
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('503')) return 'AI сервис не настроен на сервере';
    if (e.toString().contains('429')) return 'Слишком много запросов, подождите';
    return 'Не удалось получить ответ';
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(bottom: BorderSide(color: adaptiveBorder(context)))),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: adaptiveTealLt(context), border: Border.all(color: AppColors.teal.withOpacity(0.25))),
              child: Icon(Icons.auto_awesome, color: AppColors.teal, size: 22)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Ассистент', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: adaptiveText1(context))),
              Text('Спросите что угодно', style: TextStyle(fontSize: 12, color: AppColors.text4)),
            ]),
            Spacer(),
            if (_msgs.isNotEmpty) IconButton(icon: Icon(Icons.delete_outline, color: AppColors.text4), onPressed: () => setState(() => _msgs.clear())),
            Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: AppColors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle)), SizedBox(width: 4), Text('Онлайн', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green))])),
          ]),
        ),
        // Messages
        Expanded(child: _msgs.isEmpty
          ? Center(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: adaptiveTealLt(context)),
                child: Icon(Icons.auto_awesome, color: AppColors.teal, size: 36)),
              SizedBox(height: 16),
              Text('Ваш личный ИИ', style: TextStyle(fontSize: 14, color: AppColors.text3, fontWeight: FontWeight.w500)),
              SizedBox(height: 20),
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: _tips.map((t) => GestureDetector(
                onTap: () => _send(t),
                child: Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.07), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.teal.withOpacity(0.15))),
                  child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: adaptiveText1(context)))),
              )).toList()),
            ])))
          : ListView.builder(controller: _scroll, padding: EdgeInsets.all(16), itemCount: _msgs.length + (_loading ? 1 : 0), itemBuilder: (ctx, i) {
              if (i == _msgs.length) return Align(alignment: Alignment.centerLeft, child: Container(margin: EdgeInsets.only(top: 8), padding: EdgeInsets.all(14), decoration: BoxDecoration(color: adaptiveSurface2(context), borderRadius: BorderRadius.circular(16)),
                child: SizedBox(width: 50, height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)))));
              final m = _msgs[i]; final isUser = m['role'] == 'user';
              return Padding(padding: EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                if (!isUser) Padding(padding: EdgeInsets.only(bottom: 4), child: Row(children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: adaptiveTealLt(context)), child: Icon(Icons.auto_awesome, size: 12, color: AppColors.teal)),
                  SizedBox(width: 6), Text('AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                ])),
                Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: isUser ? AppColors.teal : adaptiveSurface2(context), borderRadius: BorderRadius.circular(16).copyWith(bottomRight: isUser ? Radius.circular(4) : null, bottomLeft: !isUser ? Radius.circular(4) : null),
                    boxShadow: isUser ? [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))] : null),
                  child: SelectableText(m['text'] ?? '', style: TextStyle(fontSize: 14, color: isUser ? Colors.white : adaptiveText1(context), height: 1.6))),
              ]));
            }),
        ),
        // Input
        Container(padding: EdgeInsets.fromLTRB(12, 8, 12, 88), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl,
              decoration: InputDecoration(hintText: 'Написать сообщение...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: adaptiveBorder(context))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: adaptiveBorder(context))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.teal)), contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              onSubmitted: (_) => _send(), onChanged: (_) => setState(() {}))),
            SizedBox(width: 8),
            GestureDetector(onTap: _send, child: AnimatedContainer(duration: Duration(milliseconds: 200), width: 44, height: 44,
              decoration: BoxDecoration(color: _ctrl.text.trim().isNotEmpty && !_loading ? AppColors.teal : adaptiveSurface2(context), borderRadius: BorderRadius.circular(12)),
              child: Icon(_loading ? Icons.hourglass_top : Icons.send, color: _ctrl.text.trim().isNotEmpty && !_loading ? Colors.white : AppColors.text4, size: 20))),
          ]),
        ),
      ])),
    );
  }
}
