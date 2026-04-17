import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/locataire_providers.dart';

class LocatairePaiementsScreen extends ConsumerWidget {
  const LocatairePaiementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(locatairePaiementsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text('Mes Paiements', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(locatairePaiementsProvider)),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(locatairePaiementsProvider)),
            data: (list) {
              if (list.isEmpty) return const EmptyStateWidget(icon: Icons.payments_outlined, title: 'Aucun paiement');
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(locatairePaiementsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final isPaid = p['statut'] == 'paye';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(color: (isPaid ? AppColors.success : AppColors.danger).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(isPaid ? Icons.check_circle : Icons.schedule, size: 18, color: isPaid ? AppColors.success : AppColors.danger),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(p['code_paiement'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                              StatusBadge.fromStatus(p['statut'] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Montant', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(formatCurrency(p['montant_total']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              ]),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                const Text('Payé', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(formatCurrency(p['montant_paye']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.success)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text('Échéance: ${formatDate(p['date_echeance']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const Spacer(),
                              if (p['mode_paiement'] != null) Text(p['mode_paiement'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
