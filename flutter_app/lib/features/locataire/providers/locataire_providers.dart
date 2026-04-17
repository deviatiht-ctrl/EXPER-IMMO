import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/locataire_repository.dart';

final _userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final locataireDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return null;
  return ref.read(locataireRepositoryProvider).getLocataire(uid);
});

final locataireContratProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final loc = await ref.watch(locataireDataProvider.future);
  if (loc == null) return null;
  return ref.read(locataireRepositoryProvider).getContratActif(loc['id_locataire']);
});

final locatairePaiementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final loc = await ref.watch(locataireDataProvider.future);
  if (loc == null) return [];
  return ref.read(locataireRepositoryProvider).getPaiements(loc['id_locataire']);
});

final locataireFacturesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final loc = await ref.watch(locataireDataProvider.future);
  if (loc == null) return [];
  return ref.read(locataireRepositoryProvider).getFactures(loc['id_locataire']);
});

final locataireEcheancesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final loc = await ref.watch(locataireDataProvider.future);
  if (loc == null) return [];
  return ref.read(locataireRepositoryProvider).getEcheances(loc['id_locataire']);
});

final locataireDocumentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final loc = await ref.watch(locataireDataProvider.future);
  if (loc == null) return [];
  return ref.read(locataireRepositoryProvider).getDocuments(loc['id_locataire']);
});

final locataireMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return [];
  return ref.read(locataireRepositoryProvider).getMessages(uid);
});

final locataireProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(_userIdProvider);
  if (uid == null) return null;
  return ref.read(locataireRepositoryProvider).getProfile(uid);
});
