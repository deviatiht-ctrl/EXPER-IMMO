import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

final gestionnaireRepositoryProvider = Provider<GestionnaireRepository>((ref) {
  return GestionnaireRepository(ref.watch(supabaseClientProvider));
});

class GestionnaireRepository {
  final SupabaseClient _client;
  GestionnaireRepository(this._client);

  Future<Map<String, dynamic>?> getGestionnaire(String userId) async {
    final data = await _client
        .from('gestionnaires')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> getLocataires(String gestionnaireId) async {
    final data = await _client
        .from('locataires')
        .select('id_locataire, code_locataire, nom, prenom, user:profiles!locataires_user_id_fkey(full_name, email, phone)')
        .eq('gestionnaire_responsable', gestionnaireId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getBiens(String gestionnaireId) async {
    final data = await _client
        .from('proprietes')
        .select('id_propriete, code_propriete, titre, adresse, type_propriete, statut, statut_bien, loyer_mensuel, prix_vente, images, zones(nom), proprietaire:proprietaires(code_proprietaire, user:profiles!proprietaires_user_id_fkey(full_name))')
        .eq('gestionnaire_responsable', gestionnaireId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getContrats(String gestionnaireId) async {
    final data = await _client
        .from('contrats')
        .select('id_contrat, code_contrat, reference, date_debut, date_fin, loyer_mensuel, statut, locataire:locataires(code_locataire, user:profiles!locataires_user_id_fkey(full_name)), propriete:proprietes(titre, code_propriete)')
        .eq('gestionnaire_responsable', gestionnaireId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getOperations(String gestionnaireId) async {
    final data = await _client
        .from('operations')
        .select('id_operation, code_operation, type_operation, montant, date_operation, statut_operation, remarques, publie_portail, proprietes(titre, code_propriete)')
        .eq('gestionnaire_responsable', gestionnaireId)
        .order('date_operation', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getProprietaires(String gestionnaireId) async {
    final data = await _client
        .from('proprietaires')
        .select('id_proprietaire, code_proprietaire, type_proprietaire, nom_entreprise, user:profiles!proprietaires_user_id_fkey(full_name, email, phone)')
        .eq('gestionnaire_responsable', gestionnaireId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getDocuments(String gestionnaireId) async {
    final data = await _client
        .from('documents')
        .select('*')
        .eq('gestionnaire_id', gestionnaireId)
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

  Future<Map<String, int>> getDashboardStats(String gestionnaireId) async {
    final results = await Future.wait([
      _countWhere('locataires', 'gestionnaire_responsable', gestionnaireId),
      _countWhere('proprietes', 'gestionnaire_responsable', gestionnaireId),
      _countWhere('contrats', 'gestionnaire_responsable', gestionnaireId),
      _countWhere('operations', 'gestionnaire_responsable', gestionnaireId),
    ]);
    return {
      'locataires': results[0],
      'biens': results[1],
      'contrats': results[2],
      'operations': results[3],
    };
  }

  Future<int> _countWhere(String table, String col, String val) async {
    final res = await _client.from(table).select('*', head: true).count().eq(col, val);
    return res.count ?? 0;
  }
}
