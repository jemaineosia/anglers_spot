import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/forecast_provider.dart';
import 'result/result_screen.dart';

class ForecastResultPage extends ConsumerWidget {
  final ForecastParams params;
  const ForecastResultPage({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(forecastProvider(params));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (payload) => ResultScreen(payload: payload),
    );
  }
}
