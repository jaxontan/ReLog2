/// ponytail: Cartographer's Journal OTP verification — same visual language.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/design/design_system.dart';
import '../view_models/auth_view_model.dart';

class PhoneOtpVerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const PhoneOtpVerifyScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<PhoneOtpVerifyScreen> createState() => _PhoneOtpVerifyScreenState();
}

class _PhoneOtpVerifyScreenState extends ConsumerState<PhoneOtpVerifyScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _loading = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(verifyPhoneOtpAction)(widget.phoneNumber, _code.text);
    if (!mounted) return;
    setState(() { _loading = false; _error = err; });
    if (err == null) context.go('/albums');
  }

  Future<void> _resend() async {
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(sendPhoneOtpAction)(widget.phoneNumber);
    if (!mounted) return;
    setState(() { _loading = false; _error = err; });
    if (err == null) _startResendCountdown();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
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
                        child: Icon(Icons.sms_outlined, size: 36, color: scheme.primary),
                      ),
                      const SizedBox(height: DSSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                        child: Text(
                          'Verify Your Phone',
                          style: DSTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                        child: Text(
                          'We sent a 6-digit code to ${widget.phoneNumber}',
                          style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.xxl),
                      // OTP Input
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _code,
                                decoration: const InputDecoration(
                                  hintText: 'Enter 6-digit code',
                                  prefixIcon: Icon(Icons.pin_outlined),
                                  counterText: '',
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.w600),
                                maxLength: 6,
                                onChanged: (_) => setState(() {}),
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
                      ),
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                        child: Column(
                          children: [
                            FilledButton(
                              onPressed: _loading || _code.text.length != 6 ? null : _verify,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: DSSpacing.md),
                            TextButton(
                              onPressed: _resendCountdown > 0 || _loading ? null : _resend,
                              child: Text(
                                _resendCountdown > 0 ? 'Resend code in ${_resendCountdown}s' : 'Resend code',
                              ),
                            ),
                            const SizedBox(height: DSSpacing.sm),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Back to login'),
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