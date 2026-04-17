import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/proprietaire_providers.dart';

class ProprietaireProprietesScreen extends ConsumerStatefulWidget {
  const ProprietaireProprietesScreen({super.key});

  @override
  ConsumerState<ProprietaireProprietesScreen> createState() => _State();
}

class _State extends ConsumerState<ProprietaireProprietesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(proprietaireProprietesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Mes Propriétés', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(proprietaireProprietesProvider)),
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
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(proprietaireProprietesProvider)),
            data: (list) {
              final filtered = list.where((p) {
                if (_search.isEmpty) return true;
                return (p['titre'] ?? '').toString().toLowerCase().contains(_search) ||
                    (p['code_propriete'] ?? '').toString().toLowerCase().contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.home_work_outlined, title: 'Aucune propriété');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(proprietaireProprietesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final images = p['images'] as List? ?? [];
                    final img = images.isNotEmpty ? images.first.toString() : null;

                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: img != null
                                ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, placeholder: (_, __) => Container(color: AppColors.bgTertiary))
                                : Container(color: AppColors.bgTertiary, child: const Center(child: Icon(Icons.home_work_outlined, size: 40, color: AppColors.textMuted))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(p['titre'] ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                                    StatusBadge.fromStatus(p['statut'] ?? '-'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(p['adresse'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(p['code_propriete'] ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.adminAccent)),
                                    const Spacer(),
                                    if (p['loyer_mensuel'] != null) Text(formatCurrency(p['loyer_mensuel']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                                  ],
                                ),
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
}
