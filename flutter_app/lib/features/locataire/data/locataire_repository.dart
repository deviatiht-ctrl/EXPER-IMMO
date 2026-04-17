import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

final locataireRepositoryProvider = Provider<LocataireRepository>((ref) {
  return LocataireRepository(ref.watch(supabaseClientProvider));
});

class LocataireRepository {
  final SupabaseClient _client;
  LocataireRepository(this._client);

  Future<Map<String, dynamic>?> getLocataire(String userId) async {
    final data = await _client
        .from('locataires')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
    return data;
  }

  Future<Map<String, dynamic>?> getContratActif(String locataireId) async {
    final data = await _client
        .from('contrats')
        .select('*, propriete:proprietes(titre, adresse, type_propriete, code_propriete), proprietaire:proprietaires(code_proprietaire, user:profiles!proprietaires_user_id_fkey(full_name))')
        .eq('locataire_id', locataireId)
        .eq('statut', 'actif')
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> getPaiements(String locataireId) async {
    final data = await _client
        .from('paiements')
        .select('id_paiement, code_paiement, montant_total, montant_paye, date_echeance, date_paiement, statut, mode_paiement, propriete:proprietes(titre, code_propriete)')
        .eq('locataire_id', locataireId)
        .order('date_echeance', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getFactures(String locataireId) async {
    final data = await _client
        .from('factures')
        .select('id_facture, code_facture, type_facture, montant, date_emission, date_echeance, statut_facture, periode')
        .eq('id_locataire', locataireId)
        .order('date_emission', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getEcheances(String locataireId) async {
    final data = await _client
        .from('paiements')
        .select('id_paiement, code_paiement, montant_total, date_echeance, statut')
        .eq('locataire_id', locataireId)
        .order('date_echeance', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getDocuments(String locataireId) async {
    final data = await _client
        .from('documents')
        .select('*')
        .eq('locataire_id', locataireId)
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
    return await _client.from('profiles').select('*').eq('id', userId).single();
  }
}
