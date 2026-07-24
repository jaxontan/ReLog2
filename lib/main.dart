import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  // Initialize Supabase from environment variables
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } else {
    debugPrint('Supabase not configured - set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define');
  }
  runApp(const ProviderScope(child: ReLog2App()));
}

class ReLog2App extends ConsumerWidget {
  const ReLog2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize notifications
    ref.watch(initNotificationsProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ReLog2',
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
