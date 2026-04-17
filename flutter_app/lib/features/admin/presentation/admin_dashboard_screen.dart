import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStatsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Vue d\'ensemble de votre activité', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () => const LoadingWidget(message: 'Chargement des statistiques...'),
              error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(adminStatsProvider)),
              data: (stats) => Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(label: 'Propriétaires', value: '${stats['proprietaires'] ?? 0}', icon: Icons.people, color: AppColors.adminPurple),
                      StatCard(label: 'Locataires', value: '${stats['locataires'] ?? 0}', icon: Icons.person, color: AppColors.locataireColor),
                      StatCard(label: 'Propriétés', value: '${stats['proprietes'] ?? 0}', icon: Icons.home_work, color: AppColors.proprietaireColor),
                      StatCard(label: 'Contrats actifs', value: '${stats['contrats_actifs'] ?? 0}', icon: Icons.description, color: AppColors.adminWarning),
                      StatCard(label: 'Disponibles', value: '${stats['disponibles'] ?? 0}', icon: Icons.check_circle_outline, color: AppColors.success),
                      StatCard(label: 'Loués', value: '${stats['loues'] ?? 0}', icon: Icons.vpn_key, color: AppColors.statutLoue),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _quickAction(Icons.add_home, 'Nouvelle propriété', AppColors.proprietaireColor, () {}),
            _quickAction(Icons.person_add, 'Nouveau locataire', AppColors.locataireColor, () {}),
            _quickAction(Icons.note_add, 'Nouveau contrat', AppColors.adminWarning, () {}),
            _quickAction(Icons.payments, 'Enregistrer paiement', AppColors.success, () {}),
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
