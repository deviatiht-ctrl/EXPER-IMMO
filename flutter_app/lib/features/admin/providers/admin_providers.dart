import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(adminRepositoryProvider).getDashboardStats();
});

final adminProprietairesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getProprietaires();
});

final adminLocatairesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getLocataires();
});

final adminProprietesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getProprietes();
});

final adminContratsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getContrats();
});

final adminPaiementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getPaiements();
});

final adminFacturesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getFactures();
});

final adminOperationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getOperations();
});

final adminMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getMessages();
});
