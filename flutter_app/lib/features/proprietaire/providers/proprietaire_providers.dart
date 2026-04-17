import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/proprietaire_repository.dart';

final _userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final proprietaireDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return null;
  return ref.read(proprietaireRepositoryProvider).getProprietaire(uid);
});

final proprietaireProprietesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prop = await ref.watch(proprietaireDataProvider.future);
  if (prop == null) return [];
  return ref.read(proprietaireRepositoryProvider).getProprietes(prop['id_proprietaire']);
});

final proprietaireContratsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prop = await ref.watch(proprietaireDataProvider.future);
  if (prop == null) return [];
  return ref.read(proprietaireRepositoryProvider).getContrats(prop['id_proprietaire']);
});

final proprietairePaiementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prop = await ref.watch(proprietaireDataProvider.future);
  if (prop == null) return [];
  return ref.read(proprietaireRepositoryProvider).getPaiements(prop['id_proprietaire']);
});

final proprietaireOperationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prop = await ref.watch(proprietaireDataProvider.future);
  if (prop == null) return [];
  return ref.read(proprietaireRepositoryProvider).getOperations(prop['id_proprietaire']);
});

final proprietaireDocumentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prop = await ref.watch(proprietaireDataProvider.future);
  if (prop == null) return [];
  return ref.read(proprietaireRepositoryProvider).getDocuments(prop['id_proprietaire']);
});

final proprietaireMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return [];
  return ref.read(proprietaireRepositoryProvider).getMessages(uid);
});

final proprietaireProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return null;
  return ref.read(proprietaireRepositoryProvider).getProfile(uid);
});
