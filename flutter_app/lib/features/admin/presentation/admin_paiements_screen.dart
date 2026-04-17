import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/admin_providers.dart';

class AdminPaiementsScreen extends ConsumerStatefulWidget {
  const AdminPaiementsScreen({super.key});

  @override
  ConsumerState<AdminPaiementsScreen> createState() => _AdminPaiementsScreenState();
}

class _AdminPaiementsScreenState extends ConsumerState<AdminPaiementsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(adminPaiementsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Paiements', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(adminPaiementsProvider)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search, size: 20), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(adminPaiementsProvider)),
            data: (list) {
              final filtered = list.where((p) {
                if (_search.isEmpty) return true;
                final code = (p['code_paiement'] ?? '').toString().toLowerCase();
                final loc = (p['locataire']?['user']?['full_name'] ?? '').toString().toLowerCase();
                return code.contains(_search) || loc.contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.payments_outlined, title: 'Aucun paiement');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminPaiementsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildCard(filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final code = p['code_paiement'] ?? '-';
    final locName = p['locataire']?['user']?['full_name'] ?? '-';
    final montant = p['montant_total'];
    final paye = p['montant_paye'];
    final statut = p['statut'] ?? '-';
    final mode = p['mode_paiement'] ?? '-';

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
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.payments, size: 18, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(locName, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              StatusBadge.fromStatus(statut),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Montant total', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text(formatCurrency(montant), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Payé', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text(formatCurrency(paye), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Échéance: ${formatDate(p['date_echeance']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              Text(mode, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
