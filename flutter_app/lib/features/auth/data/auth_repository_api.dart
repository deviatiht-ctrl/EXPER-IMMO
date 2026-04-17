import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/supabase/supabase_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  // Login with API fallback
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      // Try Supabase first
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Get profile from API
        try {
          final profile = await ApiClient.getProfile(authResponse.user!.id);
          return {
            'user': authResponse.user,
            'session': authResponse.session,
            'profile': profile,
          };
        } catch (e) {
          // Fallback to Supabase profile
          final profile = await _client
              .from('profiles')
              .select('*')
              .eq('id', authResponse.user!.id)
              .single();
          return {
            'user': authResponse.user,
            'session': authResponse.session,
            'profile': profile,
          };
        }
      }
      throw Exception('Login failed');
    } catch (e) {
      // Try API as fallback
      try {
        final apiResponse = await ApiClient.login(email, password);
        
        // Create mock user/session for compatibility
        final mockUser = {
          'id': apiResponse['user']['id'],
          'email': apiResponse['user']['email'],
          'user_metadata': {'role': apiResponse['user']['role']},
        };
        
        return {
          'user': mockUser,
          'session': apiResponse['session'],
          'profile': apiResponse['user'],
        };
      } catch (apiError) {
        throw Exception('Login failed: $e');
      }
    }
  }

  // Register
  Future<Map<String, dynamic>> signUpWithEmail(
    String email,
    String password,
    String fullName,
    String phone,
    String role,
  ) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );

      if (authResponse.user != null) {
        return {
          'user': authResponse.user,
          'session': authResponse.session,
        };
      }
      throw Exception('Registration failed');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      // Continue even if sign out fails
    }
  }

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Upload ID photo
  Future<String> uploadIdPhoto(String userId, String filePath) async {
    try {
      final fileBytes = await _client.storage
          .from('documents-identite')
          .upload('id_photos/$userId.jpg', File(filePath));
      
      final publicUrl = _client.storage
          .from('documents-identite')
          .getPublicUrl('id_photos/$userId.jpg');
      
      return publicUrl;
    } catch (e) {
      throw Exception('Photo upload failed: $e');
    }
  }
}
