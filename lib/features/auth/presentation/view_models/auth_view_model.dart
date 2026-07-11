import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges.map((s) => s.session?.user);
});

final loginAction = Provider.autoDispose<Future<String?> Function(String, String)>((ref) {
  return (email, pass) async {
    final (_, error) = await ref.read(authServiceProvider).signInWithEmail(email, pass);
    return error?.message;
  };
});

final registerAction = Provider.autoDispose<Future<String?> Function(String, String)>((ref) {
  return (email, pass) async {
    final (_, error) = await ref.read(authServiceProvider).registerWithEmail(email, pass);
    return error?.message;
  };
});

final signOutAction = Provider.autoDispose<Future<void> Function()>((ref) {
  return () => ref.read(authServiceProvider).signOut();
});
