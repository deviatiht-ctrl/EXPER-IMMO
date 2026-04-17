import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/locataire_providers.dart';

class LocataireDashboardScreen extends ConsumerWidget {
  const LocataireDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contratAsync = ref.watch(locataireContratProvider);
    final paiementsAsync = ref.watch(locatairePaiementsProvider);
    final facturesAsync = ref.watch(locataireFacturesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(locataireContratProvider);
        ref.invalidate(locatairePaiementsProvider);
        ref.invalidate(locataireFacturesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            const Text('Bienvenue sur votre espace locataire', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            // Stats
            Builder(builder: (_) {
              final paiements = paiementsAsync.valueOrNull ?? [];
              final factures = facturesAsync.valueOrNull ?? [];
              final payes = paiements.where((p) => p['statut'] == 'paye').length;
              final retards = paiements.where((p) => p['statut'] == 'en_retard').length;
              final factImpayees = factures.where((f) => f['statut_facture'] == 'impaye').length;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(label: 'Paiements effectués', value: '$payes', icon: Icons.check_circle, color: AppColors.success),
                  StatCard(label: 'En retard', value: '$retards', icon: Icons.warning_amber, color: AppColors.danger),
                  StatCard(label: 'Factures impayées', value: '$factImpayees', icon: Icons.receipt_long, color: AppColors.adminWarning),
                  StatCard(label: 'Total factures', value: '${factures.length}', icon: Icons.receipt, color: AppColors.adminInfo),
                ],
              );
            }),
            const SizedBox(height: 20),
            // Active contract card
            contratAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => const SizedBox.shrink(),
              data: (contrat) {
                if (contrat == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(14)),
                    child: const Column(
                      children: [
                        Icon(Icons.description_outlined, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Aucun contrat actif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.locataireColor, Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          const Text('Contrat actif', style: TextStyle(fontSize: 13, color: Colors.white70)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(100)),
                            child: const Text('Actif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(contrat['propriete']?['titre'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(contrat['propriete']?['adresse'] ?? '-', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(formatCurrency(contrat['loyer_mensuel']), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                          const Text('/mois', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${formatDate(contrat['date_debut']?.toString())} → ${formatDate(contrat['date_fin']?.toString())}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Recent payments
            paiementsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Derniers paiements', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    ...list.take(3).map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: (p['statut'] == 'paye' ? AppColors.success : AppColors.danger).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(p['statut'] == 'paye' ? Icons.check : Icons.schedule, size: 18, color: p['statut'] == 'paye' ? AppColors.success : AppColors.danger),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatCurrency(p['montant_total']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                Text('Éch. ${formatDate(p['date_echeance']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text(p['statut'] == 'paye' ? 'Payé' : p['statut'] ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p['statut'] == 'paye' ? AppColors.success : AppColors.danger)),
                        ],
                      ),
                    )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
