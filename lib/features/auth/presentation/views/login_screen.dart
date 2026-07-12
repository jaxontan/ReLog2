/// ponytail: Cartographer's Journal HTML → Flutter login. Skipped sticker animations + grid bg, add when motion asked.
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
  bool _agreed = false;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // ponytail: #fff8f6 from HTML palette — warm beige surface
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // —— Header: logo circle ——
            Container(
              width: 108, height: 108,
              decoration: BoxDecoration(
                color: scheme.surfaceDim,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C1E1A), width: 3),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: const Icon(Icons.explore, size: 48, color: Color(0xFF823B18)),
            ),
            const SizedBox(height: 12),
            Text("Cartographer's Journal", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF2C1E1A))),

            // —— Form card ——
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(children: [
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    hintText: 'Email', prefixIcon: const Icon(Icons.email),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDAC1B8))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF823B18), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  decoration: InputDecoration(
                    hintText: 'Password', prefixIcon: const Icon(Icons.lock),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDAC1B8))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF823B18), width: 1.5)),
                  ),
                  obscureText: true,
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13))),
              ]),
            ),

            // —— Button stack ——
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(children: [
                // Primary: leather brown, shadowed
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                        onTap: _loading ? null : _login,
                        child: Center(child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Column(mainAxisSize: MainAxisSize.min, children: [
                                Text('Begin Exploration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Enter your journal', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ])),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary: outlined
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C1E1A),
                      side: const BorderSide(color: Color(0xFF87736B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.go('/register'),
                    child: const Text('Create a new journal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),

            // —— Footer: agreement ——
            const SizedBox(height: 36),
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

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _pass.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(loginAction)(_email.text.trim(), _pass.text.trim());
    if (mounted) setState(() { _loading = false; _error = err; });
  }
}
