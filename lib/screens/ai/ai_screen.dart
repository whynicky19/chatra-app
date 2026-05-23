import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _loading = false;

  final _tips = ['Давай пообщаемся', 'Объясни тему кратко', 'Помоги с кодом', 'Составь план урока', 'Проверь мой текст'];

  void _send([String? override]) async {
    final text = override ?? _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() { _msgs.add({'role': 'user', 'text': text}); _loading = true; });
    _msgCtrl.clear();
    _scrollDown();

    try {
      final api = context.read<ApiService>();
      final data = await api.aiChat(text);
      final response = data['response'] ?? data['message'] ?? data['reply'] ?? 'Нет ответа';
      setState(() => _msgs.add({'role': 'assistant', 'text': response}));
    } catch (e) {
      setState(() => _msgs.add({'role': 'assistant', 'text': 'Ошибка соединения. Попробуйте позже.'}));
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: RadialGradient(colors: [AppColors.teal.withOpacity(0.25), AppColors.teal.withOpacity(0.08)]),
                      border: Border.all(color: AppColors.teal.withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(text: const TextSpan(
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Outfit'),
                        children: [
                          TextSpan(text: 'AI ', style: TextStyle(color: AppColors.text1)),
                          TextSpan(text: 'Ассистент', style: TextStyle(color: AppColors.teal)),
                        ],
                      )),
                      const Text('Спросите что угодно', style: TextStyle(fontSize: 12, color: AppColors.text4)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.green.withOpacity(0.2))),
                    child: const Text('● Онлайн', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green)),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: _msgs.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: RadialGradient(colors: [AppColors.teal.withOpacity(0.2), AppColors.teal.withOpacity(0.06)]),
                              border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppColors.teal, size: 36),
                          ),
                          const SizedBox(height: 16),
                          const Text('Ваш личный ИИ', style: TextStyle(fontSize: 14, color: AppColors.text3, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8, runSpacing: 8,
                            children: _tips.map((t) => GestureDetector(
                              onTap: () => _send(t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.teal.withOpacity(0.15)),
                                ),
                                child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text2)),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _msgs.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(16)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              for (var j = 0; j < 3; j++) ...[
                                Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.5), shape: BoxShape.circle)),
                                if (j < 2) const SizedBox(width: 4),
                              ],
                            ]),
                          ),
                        );
                      }
                      final m = _msgs[i];
                      final isUser = m['role'] == 'user';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isUser)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: AppColors.teal.withOpacity(0.15)),
                                      child: const Icon(Icons.auto_awesome, size: 12, color: AppColors.teal),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                                  ],
                                ),
                              ),
                            Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? AppColors.teal : AppColors.surface2,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isUser ? const Radius.circular(4) : null,
                                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                                ),
                                boxShadow: isUser ? [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
                              ),
                              child: SelectableText(m['text'] ?? '', style: TextStyle(fontSize: 14, color: isUser ? Colors.white : AppColors.text1, height: 1.6)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Написать сообщение...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.teal)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _msgCtrl.text.trim().isNotEmpty && !_loading ? AppColors.teal : AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _msgCtrl.text.trim().isNotEmpty ? [BoxShadow(color: AppColors.teal.withOpacity(0.4), blurRadius: 12)] : null,
                      ),
                      child: Icon(
                        _loading ? Icons.hourglass_top : Icons.send,
                        color: _msgCtrl.text.trim().isNotEmpty && !_loading ? Colors.white : AppColors.text4,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
