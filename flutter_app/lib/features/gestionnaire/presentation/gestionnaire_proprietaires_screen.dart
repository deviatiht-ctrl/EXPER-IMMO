import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/gestionnaire_providers.dart';

class GestionnaireProprietairesScreen extends ConsumerStatefulWidget {
  const GestionnaireProprietairesScreen({super.key});

  @override
  ConsumerState<GestionnaireProprietairesScreen> createState() => _State();
}

class _State extends ConsumerState<GestionnaireProprietairesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(gestionnaireProprietairesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Mes Propriétaires', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(gestionnaireProprietairesProvider)),
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
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(gestionnaireProprietairesProvider)),
            data: (list) {
              final filtered = list.where((p) {
                if (_search.isEmpty) return true;
                final name = (p['user']?['full_name'] ?? '').toString().toLowerCase();
                final code = (p['code_proprietaire'] ?? '').toString().toLowerCase();
                return name.contains(_search) || code.contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.people_outline, title: 'Aucun propriétaire');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(gestionnaireProprietairesProvider),
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
    final name = p['user']?['full_name'] ?? 'N/A';
    final email = p['user']?['email'] ?? '';
    final phone = p['user']?['phone'] ?? '';
    final code = p['code_proprietaire'] ?? '-';
    final type = p['type_proprietaire'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.proprietaireColor.withOpacity(0.1),
            child: Text(getInitials(name), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.proprietaireColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$code · $type', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.proprietaireColor), onPressed: () {}),
        ],
      ),
    );
  }
}
