/// Cartographer's Journal HTML → Flutter login. Skipped sticker animations + grid bg, add when motion asked.
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/design/design_system.dart';
import '../view_models/auth_view_model.dart';
import '../../../../features/legal/presentation/views/legal_document_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _agreed = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return DSPage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: DSSpacing.xl),
                    // Logo
                    Container(
                      width: 108, height: 108,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.15), width: 3),
                        boxShadow: DSElevation.level2,
                      ),
                      child: Icon(Icons.explore_outlined, size: 48, color: scheme.primary),
                    ),
                    const SizedBox(height: DSSpacing.lg),
                    Text(
                      "Cartographer's Journal",
                      style: DSTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DSSpacing.xxl),
                    // Form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                      child: Column(
                        children: [
                          DSTextField(
                            controller: _email,
                            hint: 'Email',
                            label: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: DSSpacing.md),
                          DSTextField(
                            controller: _pass,
                            hint: 'Password',
                            label: 'Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _loading ? null : _login(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: DSSpacing.md),
                            Text(
                              _error!,
                              style: DSTypography.bodySmall.copyWith(color: scheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Buttons
                    const SizedBox(height: DSSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                      child: Column(
                        children: [
                          DSPrimaryButton(
                            label: 'Begin Exploration',
                            subtitle: 'Enter your journal',
                            onPressed: _loading ? null : _login,
                            loading: _loading,
                          ),
                          const SizedBox(height: DSSpacing.md),
                          DSSecondaryButton(
                            label: 'Create a new journal',
                            leadingIcon: const Icon(Icons.add_outlined, size: DSIconSize.sm),
                            onPressed: () => context.go('/register'),
                          ),
                          const SizedBox(height: DSSpacing.md),
                          DSSecondaryButton(
                            label: 'Sign in with Phone',
                            leadingIcon: const Icon(Icons.phone_iphone_outlined, size: DSIconSize.sm),
                            color: scheme.primary,
                            onPressed: () => context.go('/login/phone'),
                          ),
                        ],
                      ),
                    ),
                    // Agreement
                    const SizedBox(height: DSSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: Checkbox(
                              value: _agreed,
                              onChanged: (v) => setState(() => _agreed = v ?? false),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                              side: BorderSide(color: scheme.outline),
                            ),
                          ),
                          const SizedBox(width: DSSpacing.sm),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: DSTypography.journalSmall.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.7),
                                ),
                                children: [
                                  const TextSpan(text: 'I have read and agree to the '),
                                  TextSpan(
                                    text: 'User Agreement',
                                    style: TextStyle(
                                      color: Color(0xFF823B18),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF823B18),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.openUserAgreement(),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: Color(0xFF823B18),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF823B18),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.openPrivacyPolicy(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DSSpacing.xxl),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _login() async {
    if (!_agreed) {
      setState(() => _error = 'Please agree to the User Agreement and Privacy Policy');
      return;
    }
    if (_email.text.trim().isEmpty || _pass.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(loginAction)(_email.text.trim(), _pass.text.trim());
    if (mounted) setState(() { _loading = false; _error = err; });
  }
}