import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ponytail: Firebase init fails gracefully if not configured yet
  try {
    await Firebase.initializeApp();
  } catch (_) {
    debugPrint('Firebase not configured — auth + storage will be unavailable');
  }
  runApp(const ProviderScope(child: ReLog2App()));
}

class ReLog2App extends ConsumerWidget {
  const ReLog2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
