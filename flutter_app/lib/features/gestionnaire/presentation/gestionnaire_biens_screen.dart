import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/gestionnaire_providers.dart';

class GestionnaireBiensScreen extends ConsumerStatefulWidget {
  const GestionnaireBiensScreen({super.key});

  @override
  ConsumerState<GestionnaireBiensScreen> createState() => _State();
}

class _State extends ConsumerState<GestionnaireBiensScreen> {
  String _search = '';
  String _filterStatut = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(gestionnaireBiensProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Mes Biens', style: Theme.of(context).textTheme.headlineLarge)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, size: 22),
                onSelected: (v) => setState(() => _filterStatut = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: '', child: Text('Tous')),
                  const PopupMenuItem(value: 'disponible', child: Text('Disponible')),
                  const PopupMenuItem(value: 'loue', child: Text('Loué')),
                  const PopupMenuItem(value: 'vendu', child: Text('Vendu')),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(gestionnaireBiensProvider)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search, size: 20), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(gestionnaireBiensProvider)),
            data: (list) {
              var filtered = list.where((p) {
                if (_filterStatut.isNotEmpty && p['statut'] != _filterStatut) return false;
                if (_search.isEmpty) return true;
                final titre = (p['titre'] ?? '').toString().toLowerCase();
                final code = (p['code_propriete'] ?? '').toString().toLowerCase();
                final adresse = (p['adresse'] ?? '').toString().toLowerCase();
                return titre.contains(_search) || code.contains(_search) || adresse.contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.home_work_outlined, title: 'Aucun bien');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(gestionnaireBiensProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final images = p['images'] as List<dynamic>? ?? [];
    final imgUrl = images.isNotEmpty ? images.first.toString() : null;
    final ownerName = p['proprietaire']?['user']?['full_name'] ?? '-';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: imgUrl != null
                ? CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover, placeholder: (_, __) => Container(color: AppColors.bgTertiary), errorWidget: (_, __, ___) => _placeholderImg())
                : _placeholderImg(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(p['titre'] ?? 'Sans titre', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                    StatusBadge.fromStatus(p['statut'] ?? '-'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(child: Text(p['adresse'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ownerName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
  }

  Widget _placeholderImg() {
    return Container(
      color: AppColors.bgTertiary,
      child: const Center(child: Icon(Icons.home_work_outlined, size: 40, color: AppColors.textMuted)),
    );
  }
}
