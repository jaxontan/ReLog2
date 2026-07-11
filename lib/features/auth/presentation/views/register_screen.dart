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

  @override
  void dispose() { _email.dispose(); _pass.dispose(); _confirm.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), obscureText: true),
        const SizedBox(height: 12),
        TextField(controller: _confirm, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: _loading ? null : () async {
            if (_pass.text != _confirm.text) { setState(() => _error = 'Passwords do not match'); return; }
            setState(() { _loading = true; _error = null; });
            final err = await ref.read(registerAction)(_email.text.trim(), _pass.text.trim());
            if (mounted) setState(() { _loading = false; _error = err; });
          },
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Account'),
        )),
        const SizedBox(height: 16),
        TextButton(onPressed: () => context.go('/login'), child: const Text('Already have an account? Sign in')),
      ]))),
    );
  }
}
