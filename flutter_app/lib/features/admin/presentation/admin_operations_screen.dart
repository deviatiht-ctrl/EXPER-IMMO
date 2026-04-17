import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/admin_providers.dart';

class AdminOperationsScreen extends ConsumerStatefulWidget {
  const AdminOperationsScreen({super.key});

  @override
  ConsumerState<AdminOperationsScreen> createState() => _AdminOperationsScreenState();
}

class _AdminOperationsScreenState extends ConsumerState<AdminOperationsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(adminOperationsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Opérations', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(adminOperationsProvider)),
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
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(adminOperationsProvider)),
            data: (list) {
              final filtered = list.where((o) {
                if (_search.isEmpty) return true;
                final code = (o['code_operation'] ?? '').toString().toLowerCase();
                final type = (o['type_operation'] ?? '').toString().toLowerCase();
                return code.contains(_search) || type.contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.engineering_outlined, title: 'Aucune opération');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminOperationsProvider),
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

  Widget _buildCard(Map<String, dynamic> o) {
    final code = o['code_operation'] ?? '-';
    final type = o['type_operation'] ?? '-';
    final montant = o['montant'];
    final statut = o['statut_operation'] ?? '-';
    final propTitre = o['proprietes']?['titre'] ?? '-';

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
                decoration: BoxDecoration(color: AppColors.adminPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.engineering, size: 18, color: AppColors.adminPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(type, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              StatusBadge.fromStatus(statut),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.home_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(propTitre, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              if (montant != null) Text(formatCurrency(montant), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Date: ${formatDate(o['date_operation']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
