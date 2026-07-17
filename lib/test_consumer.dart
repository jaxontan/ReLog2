import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final testProvider = Provider<int>((ref) => 42);

class TestWidget extends ConsumerWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(testProvider);
    return Text('Value: $value');
  }
}
