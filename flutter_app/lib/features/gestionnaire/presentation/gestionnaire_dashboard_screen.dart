import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/gestionnaire_providers.dart';

class GestionnaireDashboardScreen extends ConsumerWidget {
  const GestionnaireDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gestionnaireStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(gestionnaireStatsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            const Text('Vue d\'ensemble de votre activité', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () => const LoadingWidget(message: 'Chargement des statistiques...'),
              error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(gestionnaireStatsProvider)),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(label: 'Mes locataires', value: '${stats['locataires'] ?? 0}', icon: Icons.person, color: AppColors.locataireColor),
                  StatCard(label: 'Mes biens', value: '${stats['biens'] ?? 0}', icon: Icons.home_work, color: AppColors.proprietaireColor),
                  StatCard(label: 'Contrats actifs', value: '${stats['contrats'] ?? 0}', icon: Icons.description, color: AppColors.adminWarning),
                  StatCard(label: 'Opérations', value: '${stats['operations'] ?? 0}', icon: Icons.engineering, color: AppColors.adminPurple),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _quickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _quickAction(Icons.person_add, 'Nouveau locataire', AppColors.locataireColor, () {}),
            _quickAction(Icons.add_home, 'Nouveau bien', AppColors.proprietaireColor, () {}),
            _quickAction(Icons.note_add, 'Nouveau contrat', AppColors.adminWarning, () {}),
            _quickAction(Icons.engineering, 'Nouvelle opération', AppColors.adminPurple, () {}),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }
}
