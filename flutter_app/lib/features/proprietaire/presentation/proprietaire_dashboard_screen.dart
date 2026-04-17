import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/proprietaire_providers.dart';

class ProprietaireDashboardScreen extends ConsumerWidget {
  const ProprietaireDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propsAsync = ref.watch(proprietaireProprietesProvider);
    final contratsAsync = ref.watch(proprietaireContratsProvider);
    final paiementsAsync = ref.watch(proprietairePaiementsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(proprietaireProprietesProvider);
        ref.invalidate(proprietaireContratsProvider);
        ref.invalidate(proprietairePaiementsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            const Text('Bienvenue sur votre espace propriétaire', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            // Stats
            propsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(proprietaireProprietesProvider)),
              data: (props) {
                final contrats = contratsAsync.valueOrNull ?? [];
                final paiements = paiementsAsync.valueOrNull ?? [];
                final loues = props.where((p) => p['statut'] == 'loue').length;
                final dispos = props.where((p) => p['statut'] == 'disponible').length;
                final actifs = contrats.where((c) => c['statut'] == 'actif').length;
                final totalPaye = paiements.fold<num>(0, (sum, p) => sum + (p['montant_paye'] ?? 0));

                return Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        StatCard(label: 'Mes biens', value: '${props.length}', icon: Icons.home_work, color: AppColors.proprietaireColor),
                        StatCard(label: 'Loués', value: '$loues', icon: Icons.vpn_key, color: AppColors.statutLoue),
                        StatCard(label: 'Disponibles', value: '$dispos', icon: Icons.check_circle_outline, color: AppColors.success),
                        StatCard(label: 'Contrats actifs', value: '$actifs', icon: Icons.description, color: AppColors.adminWarning),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Revenue card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.proprietaireColor, Color(0xFF1439A0)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total encaissé', style: TextStyle(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(formatCurrency(totalPaye), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${paiements.length} paiement(s)', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Recent properties
                    if (props.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mes biens récents', style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...props.take(3).map((p) => _propTile(p)),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _propTile(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.home_work_outlined, size: 22, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['titre'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(p['adresse'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p['statut'] == 'loue' ? AppColors.warningBg : AppColors.successBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              p['statut'] == 'loue' ? 'Loué' : 'Disponible',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p['statut'] == 'loue' ? AppColors.warning : AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
