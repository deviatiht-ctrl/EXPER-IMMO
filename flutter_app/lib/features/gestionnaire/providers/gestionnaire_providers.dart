import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/gestionnaire_repository.dart';

final _userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final gestionnaireDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return null;
  return ref.read(gestionnaireRepositoryProvider).getGestionnaire(uid);
});

final gestionnaireStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final gest = await ref.watch(gestionnaireDataProvider.future);
  if (gest == null) return {};
  return ref.read(gestionnaireRepositoryProvider).getDashboardStats(gest['id_gestionnaire']);
});

final gestionnaireLocatairesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final gest = await ref.watch(gestionnaireDataProvider.future);
  if (gest == null) return [];
  return ref.read(gestionnaireRepositoryProvider).getLocataires(gest['id_gestionnaire']);
});

final gestionnaireBiensProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final gest = await ref.watch(gestionnaireDataProvider.future);
  if (gest == null) return [];
  return ref.read(gestionnaireRepositoryProvider).getBiens(gest['id_gestionnaire']);
});

final gestionnaireContratsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final gest = await ref.watch(gestionnaireDataProvider.future);
  if (gest == null) return [];
  return ref.read(gestionnaireRepositoryProvider).getContrats(gest['id_gestionnaire']);
});

final gestionnaireOperationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final gest = await ref.watch(gestionnaireDataProvider.future);
  if (gest == null) return [];
  return ref.read(gestionnaireRepositoryProvider).getOperations(gest['id_gestionnaire']);
});

final gestionnaireProprietairesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final gest = await ref.watch(gestionnaireDataProvider.future);
  if (gest == null) return [];
  return ref.read(gestionnaireRepositoryProvider).getProprietaires(gest['id_gestionnaire']);
});

final gestionnaireDocumentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final gest = await ref.watch(gestionnaireDataProvider.future);
  if (gest == null) return [];
  return ref.read(gestionnaireRepositoryProvider).getDocuments(gest['id_gestionnaire']);
});

final gestionnaireMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return [];
  return ref.read(gestionnaireRepositoryProvider).getMessages(uid);
});
