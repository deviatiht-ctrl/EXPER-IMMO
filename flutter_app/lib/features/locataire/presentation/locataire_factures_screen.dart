import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/locataire_providers.dart';

class LocataireFacturesScreen extends ConsumerStatefulWidget {
  const LocataireFacturesScreen({super.key});

  @override
  ConsumerState<LocataireFacturesScreen> createState() => _State();
}

class _State extends ConsumerState<LocataireFacturesScreen> {
  String _filterType = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(locataireFacturesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Mes Factures', style: Theme.of(context).textTheme.headlineLarge)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, size: 22),
                onSelected: (v) => setState(() => _filterType = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: '', child: Text('Toutes')),
                  const PopupMenuItem(value: 'eau', child: Text('Eau')),
                  const PopupMenuItem(value: 'electricite', child: Text('Électricité')),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(locataireFacturesProvider)),
            ],
          ),
        ),
        // Stats row
        dataAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (list) {
            final eau = list.where((f) => f['type_facture'] == 'eau').length;
            final elec = list.where((f) => f['type_facture'] == 'electricite').length;
            final payees = list.where((f) => f['statut_facture'] == 'paye').length;
            final dues = list.where((f) => f['statut_facture'] == 'impaye').length;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _miniStat('Eau', '$eau', AppColors.adminInfo),
                  const SizedBox(width: 8),
                  _miniStat('Élec.', '$elec', AppColors.adminWarning),
                  const SizedBox(width: 8),
                  _miniStat('Payées', '$payees', AppColors.success),
                  const SizedBox(width: 8),
                  _miniStat('Dues', '$dues', AppColors.danger),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(locataireFacturesProvider)),
            data: (list) {
              final filtered = _filterType.isEmpty ? list : list.where((f) => f['type_facture'] == _filterType).toList();
              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.receipt_long_outlined, title: 'Aucune facture');
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(locataireFacturesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final f = filtered[i];
                    final isWater = f['type_facture'] == 'eau';
                    final isPaid = f['statut_facture'] == 'paye';
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
                                decoration: BoxDecoration(color: (isWater ? AppColors.adminInfo : AppColors.adminWarning).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(isWater ? Icons.water_drop : Icons.bolt, size: 18, color: isWater ? AppColors.adminInfo : AppColors.adminWarning),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(f['code_facture'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    Text('${f['type_facture'] ?? '-'} · ${f['periode'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              StatusBadge.fromStatus(f['statut_facture'] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(formatCurrency(f['montant']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              if (!isPaid)
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.credit_card, size: 16),
                                  label: const Text('Payer'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text('Réglée', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Émission: ${formatDate(f['date_emission']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const Spacer(),
                              Text('Échéance: ${formatDate(f['date_echeance']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
