import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

/// Auth state notifier
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async {
    final sub = ref.read(authRepositoryProvider).authStateChanges.listen((event) {
      state = AsyncData(event);
    });
    ref.onDispose(() => sub.cancel());
    return null;
  }

  Future<String> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final role = await ref.read(authRepositoryProvider).signIn(email: email, password: password);
      return role;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? adresse,
    String? dateNaissance,
    String? nationalite,
    String? pieceType,
    String? pieceNumero,
    String? profession,
    String? employeur,
    String? typeProprietaire,
    String? nomEntreprise,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        adresse: adresse,
        dateNaissance: dateNaissance,
        nationalite: nationalite,
        pieceType: pieceType,
        pieceNumero: pieceNumero,
        profession: profession,
        employeur: employeur,
        typeProprietaire: typeProprietaire,
        nomEntreprise: nomEntreprise,
      );
      return user;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> resetPassword(String email) async {
    await ref.read(authRepositoryProvider).resetPassword(email);
  }
}

/// User profile provider
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.read(authRepositoryProvider).getProfile();
});

/// User role provider
final userRoleProvider = FutureProvider<String?>((ref) async {
  return ref.read(authRepositoryProvider).getUserRole();
});
