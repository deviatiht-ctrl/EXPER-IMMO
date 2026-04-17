import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/proprietaire_providers.dart';

class ProprietairePaiementsScreen extends ConsumerWidget {
  const ProprietairePaiementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(proprietairePaiementsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text('Paiements', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(proprietairePaiementsProvider)),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(proprietairePaiementsProvider)),
            data: (list) {
              if (list.isEmpty) return const EmptyStateWidget(icon: Icons.payments_outlined, title: 'Aucun paiement');
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(proprietairePaiementsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(p['code_paiement'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                              StatusBadge.fromStatus(p['statut'] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(p['locataire']?['user']?['full_name'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Total', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(formatCurrency(p['montant_total']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              ]),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                const Text('Payé', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(formatCurrency(p['montant_paye']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Échéance: ${formatDate(p['date_echeance']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
