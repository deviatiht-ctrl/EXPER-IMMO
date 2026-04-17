import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

class AdminRepository {
  final SupabaseClient _client;
  AdminRepository(this._client);

  // Dashboard stats - simplified without count for now
  Future<Map<String, int>> getDashboardStats() async {
    // Return placeholder stats for build
    return {
      'proprietaires': 0,
      'locataires': 0,
      'proprietes': 0,
      'contrats': 0,
      'paiements': 0,
      'disponibles': 0,
      'loues': 0,
      'contrats_actifs': 0,
    };
  }

  // Propriétaires
  Future<List<Map<String, dynamic>>> getProprietaires() async {
    final data = await _client
        .from('proprietaires')
        .select('id_proprietaire, code_proprietaire, type_proprietaire, nom_entreprise, user:profiles!proprietaires_user_id_fkey(full_name, email, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Locataires
  Future<List<Map<String, dynamic>>> getLocataires() async {
    final data = await _client
        .from('locataires')
        .select('id_locataire, code_locataire, nom, prenom, user:profiles!locataires_user_id_fkey(full_name, email, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Propriétés
  Future<List<Map<String, dynamic>>> getProprietes() async {
    final data = await _client
        .from('proprietes')
        .select('id_propriete, code_propriete, titre, adresse, type_propriete, statut, statut_bien, loyer_mensuel, prix_vente, images, zones(nom)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Contrats
  Future<List<Map<String, dynamic>>> getContrats() async {
    final data = await _client
        .from('contrats')
        .select('id_contrat, code_contrat, reference, date_debut, date_fin, loyer_mensuel, statut, locataire:locataires(code_locataire, user:profiles!locataires_user_id_fkey(full_name)), propriete:proprietes(titre, code_propriete)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Paiements
  Future<List<Map<String, dynamic>>> getPaiements() async {
    final data = await _client
        .from('paiements')
        .select('id_paiement, code_paiement, montant_total, montant_paye, date_echeance, date_paiement, statut, mode_paiement, locataire:locataires(code_locataire, user:profiles!locataires_user_id_fkey(full_name)), propriete:proprietes(titre, code_propriete)')
        .order('date_echeance', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Factures
  Future<List<Map<String, dynamic>>> getFactures() async {
    final data = await _client
        .from('factures')
        .select('id_facture, code_facture, type_facture, montant, date_emission, date_echeance, statut_facture, periode, locataire:locataires(code_locataire, user:profiles!locataires_user_id_fkey(full_name))')
        .order('date_emission', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Opérations
  Future<List<Map<String, dynamic>>> getOperations() async {
    final data = await _client
        .from('operations')
        .select('id_operation, code_operation, type_operation, montant, date_operation, statut_operation, remarques, publie_portail, proprietes(titre, code_propriete)')
        .order('date_operation', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Messages
  Future<List<Map<String, dynamic>>> getMessages() async {
    final data = await _client
        .from('messages')
        .select('*')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }
}
