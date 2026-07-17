/// ponytail: Cartographer's Journal phone login — same visual language.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/design/design_system.dart';
import '../view_models/auth_view_model.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phone = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(sendPhoneOtpAction)(phone);
    if (mounted) {
      setState(() { _loading = false; _error = err; });
      if (err == null) {
        context.go('/login/phone/verify', extra: phone);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
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
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.15), width: 2),
                        ),
                        child: Icon(Icons.phone_iphone_outlined, size: 36, color: scheme.primary),
                      ),
                      const SizedBox(height: DSSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                        child: Text(
                          'Sign in with Phone',
                          style: DSTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.xxl),
                      // Form
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _phone,
                                decoration: const InputDecoration(
                                  hintText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _loading ? null : _sendOtp(),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: DSSpacing.md),
                                Text(
                                  _error!,
                                  style: DSTypography.bodySmall.copyWith(color: scheme.error),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: DSSpacing.xl),
                              FilledButton(
                                onPressed: _loading ? null : _sendOtp,
                                child: _loading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Send Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: DSSpacing.md),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Use Email Instead'),
                              ),
                            ],
                          ),
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
                                value: false,
                                onChanged: (_) {},
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
                                  children: const [
                                    TextSpan(text: 'I have read and agree to the '),
                                    TextSpan(text: 'User Agreement', style: TextStyle(color: Color(0xFF823B18), fontWeight: FontWeight.w600)),
                                    TextSpan(text: ' and '),
                                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFF823B18), fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}