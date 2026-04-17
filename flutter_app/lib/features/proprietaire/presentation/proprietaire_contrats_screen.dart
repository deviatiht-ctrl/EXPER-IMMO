import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/proprietaire_providers.dart';

class ProprietaireContratsScreen extends ConsumerWidget {
  const ProprietaireContratsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(proprietaireContratsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text('Mes Contrats', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(proprietaireContratsProvider)),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(proprietaireContratsProvider)),
            data: (list) {
              if (list.isEmpty) return const EmptyStateWidget(icon: Icons.description_outlined, title: 'Aucun contrat');
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(proprietaireContratsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(c['code_contrat'] ?? c['reference'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                              StatusBadge.fromStatus(c['statut'] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(c['propriete']?['titre'] ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(c['locataire']?['user']?['full_name'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('${formatDate(c['date_debut']?.toString())} → ${formatDate(c['date_fin']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const Spacer(),
                              if (c['loyer_mensuel'] != null) Text(formatCurrency(c['loyer_mensuel']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
