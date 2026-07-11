import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';

// ponytail: email/password only. Google Sign-In deferred (google_sign_in 7.x API changed).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<(User?, Failure?)> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return (cred.user, null);
    } on FirebaseAuthException catch (e) {
      return (null, AuthFailure(_mapError(e.code)));
    }
  }

  Future<(User?, Failure?)> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return (cred.user, null);
    } on FirebaseAuthException catch (e) {
      return (null, AuthFailure(_mapError(e.code)));
    }
  }

  Future<void> signOut() async => _auth.signOut();

  String _mapError(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'email-already-in-use' => 'This email is already registered.',
        'weak-password' => 'Password is too weak.',
        'invalid-email' => 'Please enter a valid email.',
        _ => 'Something went wrong. Please try again.',
      };
}
