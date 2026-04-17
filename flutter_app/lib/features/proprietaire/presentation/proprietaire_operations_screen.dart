import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/proprietaire_providers.dart';

class ProprietaireOperationsScreen extends ConsumerWidget {
  const ProprietaireOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(proprietaireOperationsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text('Rapports & Opérations', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(proprietaireOperationsProvider)),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(proprietaireOperationsProvider)),
            data: (list) {
              final visible = list.where((o) => o['publie_portail'] == true).toList();
              if (visible.isEmpty) return const EmptyStateWidget(icon: Icons.engineering_outlined, title: 'Aucune opération publiée');
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(proprietaireOperationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final o = visible[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: AppColors.adminPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.engineering, size: 18, color: AppColors.adminPurple),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(o['code_operation'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                              StatusBadge.fromStatus(o['statut_operation'] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(o['type_operation'] ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          if (o['remarques'] != null && o['remarques'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(o['remarques'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(formatDate(o['date_operation']?.toString()), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const Spacer(),
                              if (o['montant'] != null) Text(formatCurrency(o['montant']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
