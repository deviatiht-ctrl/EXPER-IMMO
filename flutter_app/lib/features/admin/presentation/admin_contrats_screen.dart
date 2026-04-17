import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/admin_providers.dart';

class AdminContratsScreen extends ConsumerStatefulWidget {
  const AdminContratsScreen({super.key});

  @override
  ConsumerState<AdminContratsScreen> createState() => _AdminContratsScreenState();
}

class _AdminContratsScreenState extends ConsumerState<AdminContratsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(adminContratsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Contrats', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(adminContratsProvider)),
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
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(adminContratsProvider)),
            data: (list) {
              final filtered = list.where((c) {
                if (_search.isEmpty) return true;
                final code = (c['code_contrat'] ?? c['reference'] ?? '').toString().toLowerCase();
                final loc = (c['locataire']?['user']?['full_name'] ?? '').toString().toLowerCase();
                return code.contains(_search) || loc.contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.description_outlined, title: 'Aucun contrat');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminContratsProvider),
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

  Widget _buildCard(Map<String, dynamic> c) {
    final code = c['code_contrat'] ?? c['reference'] ?? '-';
    final locName = c['locataire']?['user']?['full_name'] ?? '-';
    final propTitre = c['propriete']?['titre'] ?? '-';
    final loyer = c['loyer_mensuel'];
    final statut = c['statut'] ?? '-';

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
                decoration: BoxDecoration(color: AppColors.adminWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.description, size: 18, color: AppColors.adminWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(propTitre, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(locName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              if (loyer != null) Text(formatCurrency(loyer), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('${formatDate(c['date_debut']?.toString())} → ${formatDate(c['date_fin']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
