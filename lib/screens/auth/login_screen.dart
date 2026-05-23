import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _showPw = false;
  String? _error;

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _pw.text.isEmpty) return;
    setState(() => _error = null);
    final ok = await context.read<AuthProvider>().login(_email.text.trim(), _pw.text);
    if (!ok && mounted) setState(() => _error = 'Неверный email или пароль');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Container(
          constraints: BoxConstraints(maxWidth: 420),
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.teal.withOpacity(0.2)), boxShadow: [BoxShadow(color: C.teal.withOpacity(0.08), blurRadius: 40, offset: Offset(0, 8))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [C.teal, C.tealDk])), child: Icon(Icons.school_rounded, color: Colors.white, size: 30)),
            SizedBox(height: 20),
            Text('Добро пожаловать', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.text1)),
            SizedBox(height: 4),
            Text('Войдите в свой аккаунт', style: TextStyle(fontSize: 14, color: C.text3)),
            SizedBox(height: 28),
            _label('Email'),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'you@example.com'), onSubmitted: (_) => _submit()),
            SizedBox(height: 14),
            _label('Пароль'),
            TextField(controller: _pw, obscureText: !_showPw, decoration: InputDecoration(hintText: '••••••••', suffixIcon: IconButton(icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility, color: C.text4, size: 20), onPressed: () => setState(() => _showPw = !_showPw))), onSubmitted: (_) => _submit()),
            if (_error != null) ...[SizedBox(height: 10), Container(width: double.infinity, padding: EdgeInsets.all(12), decoration: BoxDecoration(color: C.redLt, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.red.withOpacity(0.3))), child: Row(children: [Icon(Icons.error_outline, color: C.red, size: 16), SizedBox(width: 8), Expanded(child: Text(_error!, style: TextStyle(color: C.red, fontSize: 13, fontWeight: FontWeight.w500)))]))],
            SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: auth.isLoading ? null : _submit, child: auth.isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Войти'))),
            SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Нет аккаунта? ', style: TextStyle(fontSize: 13, color: C.text3)), GestureDetector(onTap: () => Navigator.pushReplacementNamed(context, '/register'), child: Text('Зарегистрируйтесь', style: TextStyle(fontSize: 13, color: C.teal, fontWeight: FontWeight.w600)))]),
          ]),
        ),
      ))),
    );
  }

  Widget _label(String s) => Padding(padding: EdgeInsets.only(bottom: 6), child: Align(alignment: Alignment.centerLeft, child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text3))));
}
