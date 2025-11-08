import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_profile.dart';
import '../services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Current auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});

// User profile provider
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final authService = ref.watch(authServiceProvider);
  return await authService.getUserProfile(user.id);
});

// Sign up provider
final signUpProvider = FutureProvider.family
    .autoDispose<AuthResponse, SignUpParams>((ref, params) async {
      final authService = ref.watch(authServiceProvider);
      return await authService.signUp(
        email: params.email,
        password: params.password,
        displayName: params.displayName,
      );
    });

// Sign in provider
final signInProvider = FutureProvider.family
    .autoDispose<AuthResponse, SignInParams>((ref, params) async {
      final authService = ref.watch(authServiceProvider);
      return await authService.signIn(
        email: params.email,
        password: params.password,
      );
    });

// Sign in anonymously provider
final signInAnonymouslyProvider = FutureProvider.autoDispose<AuthResponse>((
  ref,
) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.signInAnonymously();
});

// Sign out provider
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signOut();
});

// Parameter classes
class SignUpParams {
  final String email;
  final String password;
  final String? displayName;

  SignUpParams({required this.email, required this.password, this.displayName});
}

class SignInParams {
  final String email;
  final String password;

  SignInParams({required this.email, required this.password});
}
