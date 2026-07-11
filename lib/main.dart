import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ponytail: swap SUPABASE_URL + SUPABASE_ANON_KEY for your project. Supabase all-in (auth + data + storage).
  try {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      publishableKey: 'YOUR_SUPABASE_ANON_KEY',
    );
  } catch (_) {
    debugPrint('Supabase not configured');
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
