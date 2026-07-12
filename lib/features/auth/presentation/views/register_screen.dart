/// ponytail: Cartographer's Journal signup — same visual language as login.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/auth_view_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController(), _pass = TextEditingController(), _confirm = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _agreed = false;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); _confirm.dispose(); super.dispose(); }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint, prefixIcon: Icon(icon),
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDAC1B8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF823B18), width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: scheme.surfaceDim,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C1E1A), width: 2),
              ),
              child: const Icon(Icons.menu_book, size: 36, color: Color(0xFF823B18)),
            ),
            const SizedBox(height: 8),
            Text('Start Your Journal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF2C1E1A))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(children: [
                TextField(controller: _email, decoration: _dec('Email', Icons.email), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: _pass, decoration: _dec('Password', Icons.lock), obscureText: true),
                const SizedBox(height: 12),
                TextField(controller: _confirm, decoration: _dec('Confirm Password', Icons.lock_outline), obscureText: true),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity, height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF823B18),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Color(0xFF5A2D1A), offset: Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _loading ? null : _register,
                      child: Center(child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Open Journal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have a journal?', style: TextStyle(color: Color(0xFF823B18))),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 18, height: 18,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: const Color(0xFF823B18),
                    side: const BorderSide(color: Color(0xFFDAC1B8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(text: TextSpan(style: TextStyle(color: const Color(0xFF2C1E1A).withValues(alpha: 0.7), fontSize: 12, fontFamily: 'serif'), children: const [
                    TextSpan(text: 'I have read and agree to the '),
                    TextSpan(text: 'User Agreement', style: TextStyle(color: Color(0xFF823B18), fontWeight: FontWeight.w600)),
                    TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFF823B18), fontWeight: FontWeight.w600)),
                  ])),
                ),
              ]),
            ),
            const SizedBox(height: 48),
          ]),
            ),
          );
        })),
      ),
    );
  }

  Future<void> _register() async {
    if (_pass.text != _confirm.text) { setState(() => _error = 'Passwords do not match'); return; }
    if (_email.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(registerAction)(_email.text.trim(), _pass.text.trim());
    if (mounted) setState(() { _loading = false; _error = err; });
  }
}
