import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email + password, returns profile role for routing
  Future<String> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Connexion échouée');

    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', response.user!.id)
        .single();

    // Update last login (best-effort)
    try {
      await _client.rpc('update_derniere_connexion', params: {'p_user_id': response.user!.id});
    } catch (_) {}

    return (profile['role'] as String? ?? 'locataire').toLowerCase().trim();
  }

  /// Register a new user account (step 1: auth + profile upsert)
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
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone, 'role': role},
    );

    final user = response.user;
    if (user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'adresse': adresse,
          'date_naissance': dateNaissance,
          'nationalite': nationalite,
          'piece_identite_type': pieceType,
          'piece_identite_numero': pieceNumero,
          'profession': profession,
          'employeur': employeur,
          'type_proprietaire': typeProprietaire,
          'nom_entreprise': nomEntreprise,
          'statut_dossier': 'en_attente',
        });
      } catch (e) {
        // Profile upsert may fail if email confirmation is pending
      }
    }
    return user;
  }

  /// Upload ID photo to storage
  Future<String?> uploadIdPhoto(String userId, String side, List<int> fileBytes, String fileName) async {
    final ext = fileName.split('.').last.toLowerCase();
    final storagePath = '$userId/$side.$ext';
    try {
      await _client.storage.from('documents-identite').uploadBinary(
        storagePath,
        fileBytes as dynamic,
        fileOptions: const FileOptions(upsert: true),
      );
      return _client.storage.from('documents-identite').getPublicUrl(storagePath);
    } catch (_) {
      return null;
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Resend verification email
  Future<void> resendVerification(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current user's profile
  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await _client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();
    return data;
  }

  /// Get role from profile
  Future<String?> getUserRole() async {
    final profile = await getProfile();
    return profile?['role'] as String?;
  }
}
