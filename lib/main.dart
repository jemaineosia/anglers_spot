import 'package:anglers_spot/core/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/plan/view/planner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wawgedltfrikgpfdbjui.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indhd2dlZGx0ZnJpa2dwZmRianVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDc0NTUsImV4cCI6MjA3NDA4MzQ1NX0._X8yJzdtUOkkykZp1SkiEw3y5UumDCA6P_W_5_laOSE',
  );

  runApp(const ProviderScope(child: AnglersSpotApp()));
}

class AnglersSpotApp extends StatelessWidget {
  const AnglersSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anglers Spot',
      navigatorKey: AppNavigator.navigatorKey,
      theme: ThemeData(useMaterial3: true),
      home: const PlannerScreen(),
    );
  }
}
