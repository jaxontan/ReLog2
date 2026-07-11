import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/auth_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(), _pass = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [scheme.primary, const Color(0xFF3A1010)],
        )),
        child: SafeArea(
          child: Center(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 48),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.explore, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('RELOG2', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('Chronicle your expeditions.', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14)),
              const SizedBox(height: 40),
              Card(
                color: const Color(0xFFF5F0EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                  TextField(controller: _email, decoration: _inputDeco('Email', Icons.email)),
                  const SizedBox(height: 12),
                  TextField(controller: _pass, decoration: _inputDeco('Password', Icons.lock), obscureText: true),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13))),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _loading ? null : _login,
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('BEGIN EXPLORATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  )),
                ])),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.go('/register'), child: Text('No expedition yet? Join one.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85)))),
              const SizedBox(height: 48),
            ]),
          )),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: scheme.primary),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
    );
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _pass.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(loginAction)(_email.text.trim(), _pass.text.trim());
    if (mounted) setState(() { _loading = false; _error = err; });
  }
}
