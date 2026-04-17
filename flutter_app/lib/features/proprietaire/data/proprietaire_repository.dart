import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

final proprietaireRepositoryProvider = Provider<ProprietaireRepository>((ref) {
  return ProprietaireRepository(ref.watch(supabaseClientProvider));
});

class ProprietaireRepository {
  final SupabaseClient _client;
  ProprietaireRepository(this._client);

  Future<Map<String, dynamic>?> getProprietaire(String userId) async {
    final data = await _client
        .from('proprietaires')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> getProprietes(String proprietaireId) async {
    final data = await _client
        .from('proprietes')
        .select('id_propriete, code_propriete, titre, adresse, type_propriete, statut, statut_bien, loyer_mensuel, prix_vente, images, zones(nom)')
        .eq('proprietaire_id', proprietaireId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getContrats(String proprietaireId) async {
    final data = await _client
        .from('contrats')
        .select('id_contrat, code_contrat, reference, date_debut, date_fin, loyer_mensuel, statut, locataire:locataires(code_locataire, user:profiles!locataires_user_id_fkey(full_name)), propriete:proprietes(titre, code_propriete)')
        .eq('proprietaire_id', proprietaireId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getPaiements(String proprietaireId) async {
    final data = await _client
        .from('paiements')
        .select('id_paiement, code_paiement, montant_total, montant_paye, date_echeance, date_paiement, statut, mode_paiement, locataire:locataires(code_locataire, user:profiles!locataires_user_id_fkey(full_name)), propriete:proprietes(titre, code_propriete)')
        .eq('proprietaire_id', proprietaireId)
        .order('date_echeance', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getOperations(String proprietaireId) async {
    final data = await _client
        .from('operations')
        .select('id_operation, code_operation, type_operation, montant, date_operation, statut_operation, remarques, publie_portail, proprietes(titre, code_propriete)')
        .eq('proprietaire_id', proprietaireId)
        .order('date_operation', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getDocuments(String proprietaireId) async {
    final data = await _client
        .from('documents')
        .select('*')
        .eq('proprietaire_id', proprietaireId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    final data = await _client
        .from('messages')
        .select('*')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    return data;
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }
}
