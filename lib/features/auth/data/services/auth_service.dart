import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';

// ponytail: Supabase Auth — email/password + onAuthStateChange. Google sign-in via Supabase OAuth when needed.
class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<(User?, Failure?)> signInWithEmail(String email, String password) async {
    try {
      final res = await _auth.signInWithPassword(email: email, password: password);
      return (res.user, null);
    } on AuthException catch (e) {
      return (null, AuthFailure(_mapError(e.message)));
    }
  }

  Future<(User?, Failure?)> registerWithEmail(String email, String password) async {
    try {
      final res = await _auth.signUp(email: email, password: password);
      return (res.user, null);
    } on AuthException catch (e) {
      return (null, AuthFailure(_mapError(e.message)));
    }
  }

  /// Sends an OTP to the user's phone number via SMS.
  /// Returns null on success, or a Failure with error message.
  Future<Failure?> signInWithPhone(String phoneNumber) async {
    try {
      await _auth.signInWithOtp(phone: phoneNumber);
      return null;
    } on AuthException catch (e) {
      return AuthFailure(_mapError(e.message));
    }
  }

  /// Verifies the OTP code sent to the phone number.
  /// Returns the User on success, or a Failure on error.
  Future<(User?, Failure?)> verifyPhoneOtp(String phoneNumber, String code) async {
    try {
      final res = await _auth.verifyOTP(phone: phoneNumber, token: code, type: OtpType.sms);
      return (res.user, null);
    } on AuthException catch (e) {
      return (null, AuthFailure(_mapError(e.message)));
    }
  }

  Future<void> signOut() async => _auth.signOut();

  // ponytail: Supabase error messages are English. Map known patterns, fall through on unknown.
  String _mapError(String msg) => switch (msg) {
        String s when s.contains('Invalid login credentials') => 'Incorrect email or password.',
        String s when s.contains('already registered') => 'This email is already registered.',
        String s when s.contains('password') && s.contains('weak') => 'Password is too weak.',
        String s when s.contains('phone') && s.contains('invalid') => 'Invalid phone number format.',
        String s when s.contains('otp') && s.contains('invalid') => 'Invalid or expired code. Please try again.',
        String s when s.contains('otp') && s.contains('expired') => 'Code has expired. Please request a new one.',
        _ => 'Something went wrong. Please try again.',
      };
}
