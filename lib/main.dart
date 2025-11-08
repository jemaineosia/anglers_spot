import 'package:anglers_spot/core/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/view/welcome_screen.dart';
import 'features/main/view/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://wawgedltfrikgpfdbjui.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indhd2dlZGx0ZnJpa2dwZmRianVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDc0NTUsImV4cCI6MjA3NDA4MzQ1NX0._X8yJzdtUOkkykZp1SkiEw3y5UumDCA6P_W_5_laOSE',
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Supabase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  runApp(const ProviderScope(child: AnglersSpotApp()));
}

class AnglersSpotApp extends ConsumerWidget {
  const AnglersSpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Anglers Spot',
      navigatorKey: AppNavigator.navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state.session != null) {
          return const MainPage();
        }
        return const WelcomeScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
