import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/admin_providers.dart';

class AdminFacturesScreen extends ConsumerStatefulWidget {
  const AdminFacturesScreen({super.key});

  @override
  ConsumerState<AdminFacturesScreen> createState() => _AdminFacturesScreenState();
}

class _AdminFacturesScreenState extends ConsumerState<AdminFacturesScreen> {
  String _search = '';
  String _filterType = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(adminFacturesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Factures', style: Theme.of(context).textTheme.headlineLarge)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, size: 22),
                onSelected: (v) => setState(() => _filterType = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: '', child: Text('Toutes')),
                  const PopupMenuItem(value: 'eau', child: Text('Eau')),
                  const PopupMenuItem(value: 'electricite', child: Text('Électricité')),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(adminFacturesProvider)),
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
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(adminFacturesProvider)),
            data: (list) {
              final filtered = list.where((f) {
                if (_filterType.isNotEmpty && f['type_facture'] != _filterType) return false;
                if (_search.isEmpty) return true;
                final code = (f['code_facture'] ?? '').toString().toLowerCase();
                final loc = (f['locataire']?['user']?['full_name'] ?? '').toString().toLowerCase();
                return code.contains(_search) || loc.contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.receipt_long_outlined, title: 'Aucune facture');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminFacturesProvider),
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

  Widget _buildCard(Map<String, dynamic> f) {
    final code = f['code_facture'] ?? '-';
    final type = f['type_facture'] ?? '-';
    final locName = f['locataire']?['user']?['full_name'] ?? '-';
    final montant = f['montant'];
    final statut = f['statut_facture'] ?? '-';
    final isWater = type == 'eau';

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
                    Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('$type · $locName', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              StatusBadge.fromStatus(statut),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(formatCurrency(montant), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Période: ${f['periode'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
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
  }
}
