import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/gestionnaire_providers.dart';

class GestionnaireLocatairesScreen extends ConsumerStatefulWidget {
  const GestionnaireLocatairesScreen({super.key});

  @override
  ConsumerState<GestionnaireLocatairesScreen> createState() => _State();
}

class _State extends ConsumerState<GestionnaireLocatairesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(gestionnaireLocatairesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Mes Locataires', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(gestionnaireLocatairesProvider)),
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
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(gestionnaireLocatairesProvider)),
            data: (list) {
              final filtered = list.where((l) {
                if (_search.isEmpty) return true;
                final name = (l['user']?['full_name'] ?? '${l['prenom'] ?? ''} ${l['nom'] ?? ''}').toString().toLowerCase();
                final code = (l['code_locataire'] ?? '').toString().toLowerCase();
                return name.contains(_search) || code.contains(_search);
              }).toList();

              if (filtered.isEmpty) return const EmptyStateWidget(icon: Icons.person_outline, title: 'Aucun locataire');

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(gestionnaireLocatairesProvider),
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

  Widget _buildCard(Map<String, dynamic> l) {
    final name = l['user']?['full_name'] ?? ('${l['prenom'] ?? ''} ${l['nom'] ?? ''}').trim();
    final email = l['user']?['email'] ?? '';
    final phone = l['user']?['phone'] ?? '';
    final code = l['code_locataire'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.locataireColor.withOpacity(0.1),
            child: Text(getInitials(name), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.locataireColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'N/A' : name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(code, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.locataireColor), onPressed: () {}),
        ],
      ),
    );
  }
}
