import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/admin_providers.dart';

class AdminStatistiquesScreen extends ConsumerWidget {
  const AdminStatistiquesScreen({super.key});

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
            Text('Statistiques', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            const Text('Vue d\'ensemble chiffrée', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () => const LoadingWidget(message: 'Chargement...'),
              error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(adminStatsProvider)),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(label: 'Propriétaires', value: '${stats['proprietaires'] ?? 0}', icon: Icons.people, color: AppColors.adminPurple),
                  StatCard(label: 'Locataires', value: '${stats['locataires'] ?? 0}', icon: Icons.person, color: AppColors.locataireColor),
                  StatCard(label: 'Total propriétés', value: '${stats['proprietes'] ?? 0}', icon: Icons.home_work, color: AppColors.proprietaireColor),
                  StatCard(label: 'Total contrats', value: '${stats['contrats'] ?? 0}', icon: Icons.description, color: AppColors.adminWarning),
                  StatCard(label: 'Disponibles', value: '${stats['disponibles'] ?? 0}', icon: Icons.check_circle_outline, color: AppColors.success),
                  StatCard(label: 'Loués', value: '${stats['loues'] ?? 0}', icon: Icons.vpn_key, color: AppColors.statutLoue),
                  StatCard(label: 'Contrats actifs', value: '${stats['contrats_actifs'] ?? 0}', icon: Icons.verified, color: AppColors.adminInfo),
                  StatCard(label: 'Paiements', value: '${stats['paiements'] ?? 0}', icon: Icons.payments, color: AppColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
