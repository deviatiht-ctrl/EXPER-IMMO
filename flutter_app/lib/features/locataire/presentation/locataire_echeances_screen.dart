import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/locataire_providers.dart';

class LocataireEcheancesScreen extends ConsumerWidget {
  const LocataireEcheancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(locataireEcheancesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text('Mes Échéances', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(locataireEcheancesProvider)),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(locataireEcheancesProvider)),
            data: (list) {
              if (list.isEmpty) return const EmptyStateWidget(icon: Icons.calendar_today_outlined, title: 'Aucune échéance');

              final now = DateTime.now();
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(locataireEcheancesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = list[i];
                    final isPaid = e['statut'] == 'paye';
                    final echeance = DateTime.tryParse(e['date_echeance']?.toString() ?? '');
                    final isOverdue = !isPaid && echeance != null && echeance.isBefore(now);
                    final isSoon = !isPaid && !isOverdue && echeance != null && echeance.difference(now).inDays <= 7;

                    Color statusColor = AppColors.textMuted;
                    String statusLabel = 'À venir';
                    IconData statusIcon = Icons.schedule;

                    if (isPaid) {
                      statusColor = AppColors.success;
                      statusLabel = 'Payé';
                      statusIcon = Icons.check_circle;
                    } else if (isOverdue) {
                      statusColor = AppColors.danger;
                      statusLabel = 'En retard';
                      statusIcon = Icons.warning_amber;
                    } else if (isSoon) {
                      statusColor = AppColors.adminWarning;
                      statusLabel = 'Bientôt';
                      statusIcon = Icons.access_time;
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isOverdue ? AppColors.danger.withOpacity(0.3) : AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Date circle
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (echeance != null) ...[
                                  Text('${echeance.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
                                  Text('${_monthAbbr(echeance.month)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
                                ] else
                                  Icon(statusIcon, size: 22, color: statusColor),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatCurrency(e['montant_total']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(e['code_paiement'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                              ],
                            ),
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

  String _monthAbbr(int m) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[m - 1];
  }
}
