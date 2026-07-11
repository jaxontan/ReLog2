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

  Future<void> signOut() async => _auth.signOut();

  // ponytail: Supabase error messages are English. Map known patterns, fall through on unknown.
  String _mapError(String msg) => switch (msg) {
        String s when s.contains('Invalid login credentials') => 'Incorrect email or password.',
        String s when s.contains('already registered') => 'This email is already registered.',
        String s when s.contains('password') && s.contains('weak') => 'Password is too weak.',
        _ => 'Something went wrong. Please try again.',
      };
}
